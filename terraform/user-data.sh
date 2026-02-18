#!/bin/bash
set -e

# Update system
yum update -y

# Install Python and dependencies
yum install -y python3 python3-pip

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json <<EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/app.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "{instance_id}/application",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json

# Create application directory
mkdir -p /opt/app
cd /opt/app

# Create Flask application
cat > app.py <<'PYEOF'
from flask import Flask, jsonify
import logging
import os
from datetime import datetime

app = Flask(__name__)

# Configure logging
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
    app.run(host='0.0.0.0', port=${app_port})
PYEOF

# Install Flask
pip3 install flask boto3

# Create systemd service
cat > /etc/systemd/system/webapp.service <<EOF
[Unit]
Description=Flask Web Application
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/app
Environment="ENVIRONMENT=${environment}"
ExecStart=/usr/bin/python3 /opt/app/app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
systemctl daemon-reload
systemctl enable webapp
systemctl start webapp

# Log completion
echo "User data script completed successfully" >> /var/log/app.log
