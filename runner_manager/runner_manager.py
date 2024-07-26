from flask import Flask, request, jsonify
import subprocess

app = Flask(__name__)

def is_dind_running():
    try:
        result = subprocess.run(['docker', 'ps', '--filter', 'ancestor=docker:27.1.1-dind-rootless', '--format', '{{.ID}}'], capture_output=True, text=True)
        container_id = result.stdout.strip()
        return container_id if container_id else None
    except subprocess.CalledProcessError:
        return None

def start_dind():
    try:
        subprocess.run([
            'docker', 'run', '--rm', '-d', '--name', 'dind-instance',
            '--privileged', 'docker:27.1.1-dind-rootless'
        ], check=True)
        return is_dind_running()
    except subprocess.CalledProcessError:
        return None

@app.route('/start-runner', methods=['POST'])
def start_runner():
    data = request.json
    required_fields = [
        'container_name', 'image_tag', 'labels', 'access_token',
        'runner_name', 'runner_group', 'runner_scope', 'org_name',
        'repo_url', 'aws_access_key_id', 'aws_secret_access_key'
    ]
    
    missing_fields = [field for field in required_fields if field not in data]
    if missing_fields:
        return jsonify({'error': 'Missing required parameters', 'missing': missing_fields}), 400

    container_name = data.get('container_name')
    image_tag = data.get('image_tag')
    labels = data.get('labels')
    access_token = data.get('access_token')
    runner_name = data.get('runner_name')
    runner_group = data.get('runner_group')
    runner_scope = data.get('runner_scope')
    org_name = data.get('org_name')
    repo_url = data.get('repo_url')
    aws_access_key_id = data.get('aws_access_key_id')
    aws_secret_access_key = data.get('aws_secret_access_key')

    dind_container_id = is_dind_running()
    if not dind_container_id:
        dind_container_id = start_dind()
        if not dind_container_id:
            return jsonify({'error': 'Failed to start DinD instance'}), 500

    try:
        subprocess.run([
            'docker', 'exec', '-d', dind_container_id,
            'docker', 'run', '--rm', '--name', container_name,
            '-e', f'RUNNER_NAME={runner_name}',
            '-e', f'ACCESS_TOKEN={access_token}',
            '-e', f'RUNNER_GROUP={runner_group}',
            '-e', f'RUNNER_SCOPE={runner_scope}',
            '-e', f'ORG_NAME={org_name}',
            '-e', f'REPO_URL={repo_url}',
            '-e', 'EPHEMERAL=1',
            '-e', f'LABELS={labels}',
            '-e', f'AWS_ACCESS_KEY_ID={aws_access_key_id}',
            '-e', f'AWS_SECRET_ACCESS_KEY={aws_secret_access_key}',
            'myoung34/github-runner:' + image_tag
        ], check=True)
        return jsonify({'status': 'Runner started successfully within DinD'}), 200
    except subprocess.CalledProcessError as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
