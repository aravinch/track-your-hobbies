# app/main.py
# Entry point — run this to start the app

from src import create_app

app = create_app()

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5000)