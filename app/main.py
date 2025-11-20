from flask import Flask, request, jsonify
import os, pymysql

app = Flask(__name__)

# Get DB Credentials from Environment Variables
db_host = os.getenv("DB_HOST")
db_user = os.getenv("DB_USER", "root") # Cloud SQL default user is root
db_pass = os.getenv("DB_PASS")
db_name = os.getenv("DB_NAME", "flaskdb")

def get_db_connection():
    return pymysql.connect(host=db_host, user=db_user, password=db_pass, database=db_name, cursorclass=pymysql.cursors.DictCursor)

def init_db():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(255) NOT NULL
            )
        """)
        conn.commit()
        conn.close()
        print("Database initialized successfully")
    except Exception as e:
        print(f"DB Connection failed: {e}")

@app.route('/')
def home():
    return "GCP App running successfully! <br> /users to view data"

@app.route('/users', methods=['GET'])
def get_users():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM users;")
        rows = cursor.fetchall()
        conn.close()
        return jsonify(rows)
    except Exception as e:
        return jsonify({"error": str(e)})

@app.route('/add_user', methods=['POST'])
def add_user():
    try:
        data = request.get_json()
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("INSERT INTO users (name) VALUES (%s);", (data['name'],))
        conn.commit()
        conn.close()
        return jsonify({"message": "User added!"})
    except Exception as e:
        return jsonify({"error": str(e)})

if __name__ == "__main__":
    if db_host:
        init_db()
    app.run(host="0.0.0.0", port=5000)