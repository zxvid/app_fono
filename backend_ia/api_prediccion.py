import pandas as pd
import numpy as np
import os
import joblib
import datetime
from fastapi import FastAPI, HTTPException, Header
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import RandomForestClassifier
import warnings

# Importar helper de base de datos
from db import inicializar_db, get_connection

warnings.filterwarnings('ignore')

app = FastAPI(title="FonoSalud API Móvil & Predicción IA", version="2.0")

# Habilitar CORS para permitir solicitudes desde cualquier origen (esencial para simuladores y desarrollo web)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

EXCEL_FILE = os.path.join(os.path.dirname(__file__), 'dataset.xlsx')
MODEL_FILE = os.path.join(os.path.dirname(__file__), 'modelo_entrenado.pkl')
PREPROCESSOR_FILE = os.path.join(os.path.dirname(__file__), 'preprocesador.pkl')
COLUMNS_FILE = os.path.join(os.path.dirname(__file__), 'columnas.pkl')

def entrenar_modelo():
    if not os.path.exists(EXCEL_FILE):
        raise Exception(f"Error: No se encuentra el archivo {EXCEL_FILE}")

    print("Cargando datos desde el Excel para entrenar...")
    df = pd.read_excel(EXCEL_FILE, sheet_name='dataset', header=1)
    df = df.loc[:, ~df.columns.str.contains('^Unnamed')]
    df = df.dropna(how='all')

    target_col = 'asistio' if 'asistio' in df.columns else df.columns[-1]
    y = df[target_col].astype(str).str.lower().str.contains('si|1|asist', na=False).astype(int)

    cols_ignorar = [target_col, 'id_paciente', 'fecha_cita', 'id']
    X = df.drop(columns=[c for c in cols_ignorar if c in df.columns])

    numeric_cols = X.select_dtypes(include=['number']).columns.tolist()
    categorical_cols = X.select_dtypes(exclude=['number']).columns.tolist()

    # Normalizar texto para evitar errores de mayúsculas/minúsculas, espacios y errores de tipeo
    for col in categorical_cols:
        X[col] = X[col].astype(str).str.lower().str.strip()
        X[col] = X[col].replace({'nan': 'desconocido', 'reprogramar': 'repogramar'})

    preprocessor = ColumnTransformer(
        transformers=[
            ('num', StandardScaler(), numeric_cols),
            ('cat', OneHotEncoder(handle_unknown='ignore', sparse_output=False), categorical_cols)
        ])

    X_processed = preprocessor.fit_transform(X)

    print("Entrenando el modelo (Bosque Aleatorio para alta precisión)...")
    rna_model = RandomForestClassifier(n_estimators=100, random_state=42, class_weight='balanced')
    rna_model.fit(X_processed, y)

    joblib.dump(rna_model, MODEL_FILE)
    joblib.dump(preprocessor, PREPROCESSOR_FILE)
    joblib.dump({'numeric': numeric_cols, 'categorical': categorical_cols, 'columns': X.columns.tolist()}, COLUMNS_FILE)
    
    print("Modelo entrenado y guardado correctamente!")

@app.on_event("startup")
def startup_event():
    # Inicializar la base de datos SQLite y sembrar datos de prueba
    try:
        inicializar_db()
    except Exception as e:
        print(f"Error al inicializar la base de datos: {e}")

    # Inicializar modelo de IA si no existe
    if not (os.path.exists(MODEL_FILE) and os.path.exists(PREPROCESSOR_FILE)):
        try:
            entrenar_modelo()
        except Exception as e:
            print(f"Error al entrenar el modelo de IA: {e}")

# ==================== MODELOS PYDANTIC ====================

class LoginRequest(BaseModel):
    username: str
    password: str

class RegisterRequest(BaseModel):
    nombre: str
    user: str
    contrasena: str

class CitaRequest(BaseModel):
    idFonoaudiologo: int
    sintomas: str
    fecha_hora: str  # Formato ISO (ej. 2026-05-20T10:00:00)

class DatosPaciente(BaseModel):
    datos: dict 

# ==================== HELPERS DE AUTENTICACIÓN ====================

def obtener_usuario_autenticado(authorization: str = Header(None)):
    """Valida el token de sesión y retorna la información del usuario correspondiente."""
    if not authorization:
        raise HTTPException(status_code=401, detail="Falta cabecera de Autorización")
    
    try:
        # Formato esperado: "Bearer session-token-<id>-<email>"
        partes = authorization.split(" ")
        if len(partes) != 2 or partes[0].lower() != "bearer":
            raise HTTPException(status_code=401, detail="Formato de token inválido")
        
        token = partes[1]
        if not token.startswith("session-token-"):
            raise HTTPException(status_code=401, detail="Token no válido")
        
        token_partes = token.split("-")
        if len(token_partes) < 4:
            raise HTTPException(status_code=401, detail="Token mal formado")
        
        user_id = int(token_partes[2])
        user_email = token_partes[3]
        
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT id, nombre, user, role FROM users WHERE id = ? AND user = ?", (user_id, user_email))
        usuario = cursor.fetchone()
        conn.close()
        
        if not usuario:
            raise HTTPException(status_code=401, detail="Sesión expirada o usuario no encontrado")
        
        return dict(usuario)
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=401, detail=f"Error de autenticación: {str(e)}")

# ==================== ENDPOINTS DE AUTENTICACIÓN ====================

@app.post("/auth/register")
def register(req: RegisterRequest):
    conn = get_connection()
    cursor = conn.cursor()
    try:
        # Verificar si el usuario ya existe
        cursor.execute("SELECT id FROM users WHERE user = ?", (req.user,))
        if cursor.fetchone():
            raise HTTPException(status_code=400, detail="El correo de usuario ya se encuentra registrado")
        
        # Insertar nuevo usuario con rol de USER por defecto
        cursor.execute(
            "INSERT INTO users (nombre, user, contrasena, role) VALUES (?, ?, ?, 'USER')",
            (req.nombre, req.user, req.contrasena)
        )
        conn.commit()
        
        # Obtener el ID del nuevo usuario
        user_id = cursor.lastrowid
        
        # Crear token de sesión con el formato auto-parsea-ble
        token = f"session-token-{user_id}-{req.user}"
        
        return {"jwt": token}
    except Exception as e:
        conn.rollback()
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        conn.close()

@app.post("/auth/login")
def login(req: LoginRequest):
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            "SELECT id, nombre, user, role FROM users WHERE user = ? AND contrasena = ?",
            (req.username, req.password)
        )
        usuario = cursor.fetchone()
        
        if not usuario:
            raise HTTPException(status_code=401, detail="Credenciales incorrectas")
        
        user_id = usuario['id']
        user_email = usuario['user']
        
        # Generar token
        token = f"session-token-{user_id}-{user_email}"
        
        return {"jwt": token}
    finally:
        conn.close()

# ==================== ENDPOINTS DE FONOAUDIÓLOGOS ====================

@app.get("/api/fonoaudiologos")
def get_fonoaudiologos():
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT id, nombre, email FROM fonoaudiologo")
        fonoaudiologos = [dict(row) for row in cursor.fetchall()]
        return fonoaudiologos
    finally:
        conn.close()

# ==================== ENDPOINTS DE CITAS ====================

@app.post("/api/citas", status_code=201)
def create_cita(cita: CitaRequest, authorization: str = Header(None)):
    usuario_autenticado = obtener_usuario_autenticado(authorization)
    
    conn = get_connection()
    cursor = conn.cursor()
    try:
        # Verificar que el fonoaudiólogo exista
        cursor.execute("SELECT id, nombre, email FROM fonoaudiologo WHERE id = ?", (cita.idFonoaudiologo,))
        fonoaudiologo = cursor.fetchone()
        if not fonoaudiologo:
            raise HTTPException(status_code=404, detail="El fonoaudiólogo seleccionado no existe")
        
        # Verificar duplicados para el fonoaudiólogo a la misma hora
        cursor.execute(
            "SELECT id FROM cita WHERE id_fonoaudiologo = ? AND fecha_hora = ?",
            (cita.idFonoaudiologo, cita.fecha_hora)
        )
        if cursor.fetchone():
            raise HTTPException(
                status_code=400,
                detail="El fonoaudiólogo ya tiene asignada una cita con esa fecha y hora"
            )
        
        # Insertar cita
        cursor.execute(
            "INSERT INTO cita (id_paciente, id_fonoaudiologo, sintomas, fecha_hora) VALUES (?, ?, ?, ?)",
            (usuario_autenticado['id'], cita.idFonoaudiologo, cita.sintomas, cita.fecha_hora)
        )
        conn.commit()
        
        cita_id = cursor.lastrowid
        
        # Armar respuesta idéntica al modelo relacional de JPA
        return {
            "id": cita_id,
            "idPaciente": {
                "id": usuario_autenticado['id'],
                "nombre": usuario_autenticado['nombre'],
                "user": usuario_autenticado['user'],
                "role": usuario_autenticado['role']
            },
            "idFonoaudiologo": {
                "id": fonoaudiologo['id'],
                "nombre": fonoaudiologo['nombre'],
                "email": fonoaudiologo['email']
            },
            "sintomas": cita.sintomas,
            "fecha_hora": cita.fecha_hora
        }
    except Exception as e:
        conn.rollback()
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        conn.close()

@app.get("/api/citas/find/paciente")
def get_citas_paciente(authorization: str = Header(None)):
    usuario_autenticado = obtener_usuario_autenticado(authorization)
    
    conn = get_connection()
    cursor = conn.cursor()
    try:
        # Obtener todas las citas del paciente uniendo las tablas para resolver el nombre del fonoaudiólogo
        cursor.execute("""
            SELECT 
                c.id as cita_id, 
                c.sintomas, 
                c.fecha_hora,
                f.id as fono_id, 
                f.nombre as fono_nombre, 
                f.email as fono_email
            FROM cita c
            JOIN fonoaudiologo f ON c.id_fonoaudiologo = f.id
            WHERE c.id_paciente = ?
            ORDER BY c.fecha_hora ASC
        """, (usuario_autenticado['id'],))
        
        filas = cursor.fetchall()
        citas = []
        for fila in filas:
            citas.append({
                "id": fila["cita_id"],
                "idPaciente": {
                    "id": usuario_autenticado['id'],
                    "nombre": usuario_autenticado['nombre'],
                    "user": usuario_autenticado['user'],
                    "role": usuario_autenticado['role']
                },
                "idFonoaudiologo": {
                    "id": fila["fono_id"],
                    "nombre": fila["fono_nombre"],
                    "email": fila["fono_email"]
                },
                "sintomas": fila["sintomas"],
                "fecha_hora": fila["fecha_hora"]
            })
        
        return citas
    finally:
        conn.close()

@app.delete("/api/citas/{id}", status_code=204)
def delete_cita(id: int, authorization: str = Header(None)):
    usuario_autenticado = obtener_usuario_autenticado(authorization)
    
    conn = get_connection()
    cursor = conn.cursor()
    try:
        # Verificar que la cita pertenezca al paciente
        cursor.execute("SELECT id_paciente FROM cita WHERE id = ?", (id,))
        cita = cursor.fetchone()
        if not cita:
            raise HTTPException(status_code=404, detail="La cita no existe")
        
        if cita['id_paciente'] != usuario_autenticado['id']:
            raise HTTPException(status_code=403, detail="No tiene permisos para cancelar esta cita")
        
        cursor.execute("DELETE FROM cita WHERE id = ?", (id,))
        conn.commit()
        return None
    except Exception as e:
        conn.rollback()
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        conn.close()

# ==================== ENDPOINT DE PREDICCIÓN CON IA ====================

@app.post("/predecir")
def predecir_asistencia(paciente: DatosPaciente):
    try:
        # 1. Cargar el dataset en cada petición para buscar coincidencias exactas
        if not os.path.exists(EXCEL_FILE):
            raise HTTPException(status_code=500, detail="Archivo dataset.xlsx no encontrado.")
            
        # Leemos el excel de forma más robusta
        df = pd.read_excel(EXCEL_FILE, sheet_name='dataset', header=1)
        
        # Limpiar columnas vacías y filas nulas
        df = df.loc[:, ~df.columns.str.contains('^Unnamed')]
        df = df.dropna(subset=['edad', 'genero', 'especialidad', 'asistio'])

        # Normalizar datos de entrada del paciente
        def clean_val(v):
            return str(v).lower().strip() if pd.notnull(v) else ""

        entrada_edad = clean_val(paciente.datos.get('edad', ''))
        entrada_genero = clean_val(paciente.datos.get('genero', ''))
        entrada_especialidad = clean_val(paciente.datos.get('especialidad', ''))
        entrada_observaciones = clean_val(paciente.datos.get('observaciones', ''))
        
        # 2. Búsqueda de coincidencia exacta
        # Convertimos las columnas del DF a string limpio para comparar
        def match_row(row):
            # Comparamos edad (manejando que pueda ser 5 o 5.0 en el excel)
            row_edad = str(int(float(row['edad']))) if pd.notnull(row['edad']) else ""
            
            match = (
                row_edad == entrada_edad and
                clean_val(row['genero']) == entrada_genero and
                clean_val(row['especialidad']) == entrada_especialidad and
                clean_val(row['observaciones']) == entrada_observaciones
            )
            return match

        coincidencia = df[df.apply(match_row, axis=1)]
        
        if not coincidencia.empty:
            # Si existe en el dataset, devolvemos el valor real con 100% de confianza
            valor_real = coincidencia.iloc[0]['asistio']
            # Normalizar el valor de 'asistio'
            asistio_str = clean_val(valor_real)
            prediccion = 1 if asistio_str in ['si', '1', 'asistio', 's'] else 0
            
            return {
                "prediccion": prediccion,
                "resultado_texto": "Asistió" if prediccion == 1 else "No Asistió",
                "confianza_porcentaje": 100.0,
                "fuente": "Dataset (Coincidencia Exacta)"
            }

        # 3. Si no hay coincidencia exacta, usamos el modelo de IA (Random Forest)
        if not (os.path.exists(MODEL_FILE) and os.path.exists(PREPROCESSOR_FILE) and os.path.exists(COLUMNS_FILE)):
            entrenar_modelo() # Re-entrenar si faltan archivos
            
        rna_model = joblib.load(MODEL_FILE)
        preprocessor = joblib.load(PREPROCESSOR_FILE)
        cols_info = joblib.load(COLUMNS_FILE)

        df_nuevo = pd.DataFrame([paciente.datos])

        for col in cols_info['columns']:
            if col not in df_nuevo.columns:
                if col in cols_info['numeric']:
                    df_nuevo[col] = 0
                else:
                    df_nuevo[col] = 'Desconocido'
        
        df_nuevo = df_nuevo[cols_info['columns']]

        for col in cols_info['categorical']:
            df_nuevo[col] = df_nuevo[col].astype(str).str.lower().str.strip()
            if col == 'observaciones':
                df_nuevo[col] = df_nuevo[col].replace('reprogramar', 'repogramar')

        X_nuevo = preprocessor.transform(df_nuevo)

        prediccion = rna_model.predict(X_nuevo)[0]
        probabilidades = rna_model.predict_proba(X_nuevo)[0]
        
        resultado_texto = "Asistió" if prediccion == 1 else "No Asistió"
        confianza = probabilidades[prediccion] * 100

        return {
            "prediccion": int(prediccion),
            "resultado_texto": resultado_texto,
            "confianza_porcentaje": round(confianza, 2),
            "fuente": "IA (Random Forest)"
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/")
def home():
    return {
        "mensaje": "Servidor Móvil Consolidado FonoSalud (FastAPI + SQLite + IA)",
        "estado": "Online",
        "endpoints": [
            "POST /auth/login",
            "POST /auth/register",
            "GET /api/fonoaudiologos",
            "POST /api/citas",
            "GET /api/citas/find/paciente",
            "DELETE /api/citas/{id}",
            "POST /predecir"
        ]
    }

if __name__ == '__main__':
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
