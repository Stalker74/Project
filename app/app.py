from flask import Flask, jsonify
import logging
import os
from datetime import datetime

app = Flask(__name__)

logging.basicConfig(
    filename='/var/log/app.log',
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

@app.route('/')
def home():
    app.logger.info('Home endpoint accessed')
    return jsonify({
        'status': 'healthy',
        'message': 'Production Infrastructure Demo',
        'timestamp': datetime.now().isoformat(),
        'environment': os.environ.get('ENVIRONMENT', 'unknown')
    })

@app.route('/health')
def health():
    app.logger.info('Health check performed')
    return jsonify({'status': 'ok'}), 200

if __name__ == '__main__':
    app.logger.info('Application starting...')
    app.run(host='0.0.0.0', port=5000)
