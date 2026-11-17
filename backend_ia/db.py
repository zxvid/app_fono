import sqlite3
import os

DB_PATH = os.path.join(os.path.dirname(__file__), 'fonosalud.db')

def get_connection():
    """Retorna una conexión activa a la base de datos SQLite."""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row  # Permite acceder a las columnas por nombre
    return conn

def inicializar_db():
    """Crea las tablas necesarias en SQLite y siembra los datos de prueba si están vacías."""
    print("Inicializando la base de datos SQLite...")
    conn = get_connection()
    cursor = conn.cursor()

    # Limpiar tablas existentes para asegurar que los datos coincidan con lo solicitado
    cursor.execute("DROP TABLE IF EXISTS cita")
    cursor.execute("DROP TABLE IF EXISTS fonoaudiologo")
    cursor.execute("DROP TABLE IF EXISTS users")

    # Tabla de Usuarios (Pacientes y Fonoaudiólogos)
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        user TEXT UNIQUE NOT NULL,
        contrasena TEXT NOT NULL,
        role TEXT NOT NULL
    );
    """)

    # Tabla de Fonoaudiólogos (Mapeo directo)
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS fonoaudiologo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        contrasena TEXT NOT NULL
    );
    """)

    # Tabla de Citas
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS cita (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_paciente INTEGER NOT NULL,
        id_fonoaudiologo INTEGER NOT NULL,
        sintomas TEXT NOT NULL,
        fecha_hora TEXT NOT NULL,
        FOREIGN KEY(id_paciente) REFERENCES users(id),
        FOREIGN KEY(id_fonoaudiologo) REFERENCES fonoaudiologo(id)
    );
    """)

    # Tabla de Notificaciones
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS notificacion (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_usuario INTEGER NOT NULL,
        titulo TEXT NOT NULL,
        descripcion TEXT NOT NULL,
        tipo TEXT NOT NULL, -- 'AGENDADA', 'CANCELADA'
        leida INTEGER DEFAULT 0,
        fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (id_usuario) REFERENCES users (id)
    )
    """)

    conn.commit()

    # Sembrar datos de prueba si la tabla de usuarios está vacía
    cursor.execute("SELECT COUNT(*) FROM users")
    if cursor.fetchone()[0] == 0:
        print("Sembrando datos de prueba iniciales...")
        
        # 1. Sembrar Fonoaudiólogos en ambas tablas (users con rol FONAUDIOLOGO y fonoaudiologo)
        fonoaudiologos_data = [
            (1, "Dr. Jeison Zuñiga", "jeison", "123456", "FONAUDIOLOGO"),
            (2, "Dr. Orozco", "orozco", "123456", "FONAUDIOLOGO"),
            (3, "Dr. Toscano", "toscano", "123456", "FONAUDIOLOGO")
        ]
        
        for fid, nombre, email, contra, rol in fonoaudiologos_data:
            # Insertar en users
            cursor.execute(
                "INSERT INTO users (id, nombre, user, contrasena, role) VALUES (?, ?, ?, ?, ?)",
                (fid, nombre, email, contra, rol)
            )
            # Insertar en fonoaudiologo
            cursor.execute(
                "INSERT INTO fonoaudiologo (id, nombre, email, contrasena) VALUES (?, ?, ?, ?)",
                (fid, nombre, email, contra)
            )

        # 2. Sembrar pacientes de prueba
        cursor.execute(
            "INSERT INTO users (nombre, user, contrasena, role) VALUES (?, ?, ?, ?)",
            ("David", "david@mail.com", "123456", "USER")
        )
        cursor.execute(
            "INSERT INTO users (nombre, user, contrasena, role) VALUES (?, ?, ?, ?)",
            ("Carlos", "carlos", "123456", "USER")
        )
        
        # 3. Sembrar una cita inicial para David (ID = 4) con Dr. Jeison Zuñiga (ID = 1)
        # Fecha estimada: "Mañana, 10:00 AM" -> Pongamos una fecha futura real formateada en ISO
        import datetime
        tomorrow = datetime.datetime.now() + datetime.timedelta(days=1)
        tomorrow_str = tomorrow.strftime("%Y-%m-%dT10:00:00")
        cursor.execute(
            "INSERT INTO cita (id_paciente, id_fonoaudiologo, sintomas, fecha_hora) VALUES (?, ?, ?, ?)",
            (4, 1, "Dificultad de audición leve en el oído izquierdo al despertar.", tomorrow_str)
        )

        conn.commit()
        print("Siembra de base de datos completada exitosamente!")
    
    conn.close()

if __name__ == '__main__':
    inicializar_db()
