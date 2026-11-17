"""API REST para la aplicación FonoSalud.
Provee endpoints para:
- Autenticación de usuarios (pacientes y fonoaudiólogos).
- Obtención de citas del doctor.
- Creación y cancelación de citas.

Se basa en la base de datos SQLite definida en db.py.
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import sqlite3
from pathlib import Path
import datetime

app = Flask(__name__)
CORS(app)  # Permite que la app Flutter haga peticiones desde cualquier origen.

# Ruta al archivo DB (reutilizamos la constante de db.py)
DB_PATH = Path(__file__).parent / "fonosalud.db"

def get_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

# ---------------------------------------------------------------------
# Utilidades de base de datos
# ---------------------------------------------------------------------
def obtener_usuario_por_email(email: str):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM users WHERE user = ?", (email,))
    row = cur.fetchone()
    conn.close()
    return dict(row) if row else None

def obtener_citas_doctor(doctor_id: int):
    conn = get_connection()
    cur = conn.cursor()
    # Unimos con la tabla users para obtener el nombre del paciente
    cur.execute("""
        SELECT c.id, c.id_paciente, c.sintomas, c.fecha_hora, u.nombre as nombre_paciente, u.user as email_paciente
        FROM cita c
        JOIN users u ON c.id_paciente = u.id
        WHERE c.id_fonoaudiologo = ?
        ORDER BY c.fecha_hora ASC
    """, (doctor_id,))
    rows = cur.fetchall()
    conn.close()
    
    citas = []
    for r in rows:
        citas.append({
            "id": r['id'],
            "idPaciente": {
                "id": r['id_paciente'],
                "nombre": r['nombre_paciente'],
                "user": r['email_paciente']
            },
            "sintomas": r['sintomas'],
            "fecha_hora": r['fecha_hora']
        })
    return citas

def obtener_citas_paciente(paciente_id: int):
    conn = get_connection()
    cur = conn.cursor()
    # Unimos con la tabla fonoaudiologo para obtener el nombre del doctor
    cur.execute("""
        SELECT c.id, c.id_fonoaudiologo, c.sintomas, c.fecha_hora, f.nombre as nombre_doctor, f.email as email_doctor
        FROM cita c
        JOIN fonoaudiologo f ON c.id_fonoaudiologo = f.id
        WHERE c.id_paciente = ?
        ORDER BY c.fecha_hora ASC
    """, (paciente_id,))
    rows = cur.fetchall()
    conn.close()
    
    citas = []
    for r in rows:
        citas.append({
            "id": r['id'],
            "idFonoaudiologo": {
                "id": r['id_fonoaudiologo'],
                "nombre": r['nombre_doctor'],
                "email": r['email_doctor']
            },
            "sintomas": r['sintomas'],
            "fecha_hora": r['fecha_hora']
        })
    return citas

def crear_cita(id_paciente: int, id_fono: int, sintomas: str, fecha_hora: str):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        "INSERT INTO cita (id_paciente, id_fonoaudiologo, sintomas, fecha_hora) VALUES (?, ?, ?, ?)",
        (id_paciente, id_fono, sintomas, fecha_hora)
    )
    cita_id = cur.lastrowid
    
    # Crear notificación para el doctor
    cur.execute("SELECT nombre FROM users WHERE id = ?", (id_paciente,))
    paciente = cur.fetchone()
    nombre_paciente = paciente['nombre'] if paciente else "Un paciente"
    
    cur.execute(
        "INSERT INTO notificacion (id_usuario, titulo, descripcion, tipo) VALUES (?, ?, ?, ?)",
        (id_fono, "Nueva Cita Agendada", f"{nombre_paciente} ha reservado una cita para el {fecha_hora}.", "AGENDADA")
    )
    
    conn.commit()
    conn.close()
    return cita_id

def cancelar_cita(cita_id: int):
    conn = get_connection()
    cur = conn.cursor()
    
    # Obtener info antes de borrar para notificar
    cur.execute("SELECT id_paciente, id_fonoaudiologo, fecha_hora FROM cita WHERE id = ?", (cita_id,))
    cita = cur.fetchone()
    
    if not cita:
        conn.close()
        return False
        
    id_paciente = cita['id_paciente']
    id_fono = cita['id_fonoaudiologo']
    fecha = cita['fecha_hora']
    
    cur.execute("SELECT nombre FROM users WHERE id = ?", (id_paciente,))
    paciente = cur.fetchone()
    nombre_paciente = paciente['nombre'] if paciente else "Un paciente"

    cur.execute("DELETE FROM cita WHERE id = ?", (cita_id,))
    
    # Crear notificación de cancelación para el doctor
    cur.execute(
        "INSERT INTO notificacion (id_usuario, titulo, descripcion, tipo) VALUES (?, ?, ?, ?)",
        (id_fono, "Cita Cancelada", f"{nombre_paciente} ha cancelado su cita del {fecha}.", "CANCELADA")
    )
    
    conn.commit()
    conn.close()
    return True

def obtener_notificaciones(usuario_id: int):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT id, titulo, descripcion, tipo, leida, fecha_creacion 
        FROM notificacion 
        WHERE id_usuario = ? 
        ORDER BY fecha_creacion DESC
    """, (usuario_id,))
    rows = cur.fetchall()
    conn.close()
    return [dict(r) for r in rows]

def marcar_notificaciones_leidas(usuario_id: int):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("UPDATE notificacion SET leida = 1 WHERE id_usuario = ?", (usuario_id,))
    conn.commit()
    conn.close()

# ---------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------
@app.route('/login', methods=['POST'])
def login():
    """Recibe JSON {"email": "...", "password": "..."} y devuelve información del usuario.
    Si las credenciales son válidas, responde con:
    {"success": true, "user": {"id": ..., "nombre": ..., "role": ...}}
    En caso contrario: {"success": false, "error": "Credenciales inválidas"}
    """
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')
    user = obtener_usuario_por_email(email)
    if user and user['contrasena'] == password:
        return jsonify({
            'success': True,
            'user': {
                'id': user['id'],
                'nombre': user['nombre'],
                'role': user['role']
            }
        })
    return jsonify({'success': False, 'error': 'Credenciales inválidas'}), 401

@app.route('/doctor/<int:doctor_id>/citas', methods=['GET'])
def citas_doctor(doctor_id):
    """Devuelve la lista de citas asignadas al doctor especificado.
    Cada cita contiene id, paciente, sintomas y fecha_hora.
    """
    citas = obtener_citas_doctor(doctor_id)
    return jsonify({'citas': citas})

@app.route('/paciente/<int:paciente_id>/citas', methods=['GET'])
def citas_paciente(paciente_id):
    """Devuelve la lista de citas del paciente especificado.
    Cada cita contiene id, doctor, sintomas y fecha_hora.
    """
    citas = obtener_citas_paciente(paciente_id)
    return jsonify({'citas': citas})

@app.route('/fonoaudiologos', methods=['GET'])
def fonoaudiologos():
    """Devuelve la lista de todos los fonoaudiólogos disponibles."""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT id, nombre, email FROM fonoaudiologo")
    rows = cur.fetchall()
    conn.close()
    return jsonify([dict(r) for r in rows])

@app.route('/cita', methods=['POST'])
def crear_nueva_cita():
    """Crea una cita.
    Parámetros JSON esperados:
    {
        "id_paciente": int,
        "id_fono": int,
        "sintomas": "...",
        "fecha_hora": "YYYY-MM-DDTHH:MM:SS"
    }
    """
    data = request.get_json()
    cita_id = crear_cita(
        data['id_paciente'],
        data['id_fono'],
        data['sintomas'],
        data['fecha_hora']
    )
    return jsonify({'success': True, 'cita_id': cita_id}), 201

@app.route('/cita/<int:cita_id>', methods=['DELETE'])
def eliminar_cita(cita_id):
    """Cancela (elimina) una cita existente."""
    ok = cancelar_cita(cita_id)
    if ok:
        return jsonify({'success': True})
    return jsonify({'success': False, 'error': 'Cita no encontrada'}), 404

@app.route('/notificaciones/<int:usuario_id>', methods=['GET'])
def get_notificaciones(usuario_id):
    """Devuelve las notificaciones de un usuario."""
    notificaciones = obtener_notificaciones(usuario_id)
    return jsonify({'notificaciones': notificaciones})

@app.route('/notificaciones/<int:usuario_id>/leer', methods=['POST'])
def leer_notificaciones(usuario_id):
    """Marca todas las notificaciones como leídas."""
    marcar_notificaciones_leidas(usuario_id)
    return jsonify({'success': True})

# ---------------------------------------------------------------------
# Ejecutar servidor (solo para desarrollo)
# ---------------------------------------------------------------------
if __name__ == '__main__':
    # Puerto configurable; por defecto 5000
    app.run(host='0.0.0.0', port=5000, debug=True)
