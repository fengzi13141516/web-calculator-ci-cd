from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/')
def index():
    return jsonify({
        "name": "Web Calculator",
        "version": "1.0.0",
        "endpoints": ["/add/<a>&<b>", "/multiply/<a>&<b>", "/health"]
    })

@app.route('/add/<a>&<b>')
def add(a, b):
    try:
        result = float(a) + float(b)
        return jsonify({"operation": "add", "a": a, "b": b, "result": result})
    except ValueError:
        return jsonify({"error": "Invalid input"}), 400

@app.route('/multiply/<a>&<b>')
def multiply(a, b):
    try:
        result = float(a) * float(b)
        return jsonify({"operation": "multiply", "a": a, "b": b, "result": result})
    except ValueError:
        return jsonify({"error": "Invalid input"}), 400

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "service": "web-calculator"})

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)