from flask import Flask, request, jsonify
import subprocess

app = Flask(__name__)

@app.route('/start-runner', methods=['POST'])
def start_runner():
    data = request.json
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
    uid = 1001  # Non-root user ID inside the container

    if not all([container_name, image_tag, labels, access_token, runner_name, runner_group, runner_scope, org_name, repo_url, aws_access_key_id, aws_secret_access_key]):
        return jsonify({'error': 'Missing required parameters'}), 400

    try:
        subprocess.run([
            'docker', 'run', '--user', str(uid), '--rm', '-d', '--privileged', '--name', container_name,
            '-e', f'RUNNER_NAME={runner_name}',
            '-e', f'ACCESS_TOKEN={access_token}',
            '-e', f'RUNNER_GROUP={runner_group}',
            '-e', f'RUNNER_SCOPE={runner_scope}',
            '-e', f'ORG_NAME={org_name}',
            '-e', f'REPO_URL={repo_url}',
            '-e', f'LABELS={labels}',
            '-e', 'RUN_AS_ROOT=false',
            '-e', f'AWS_ACCESS_KEY_ID={aws_access_key_id}',
            '-e', f'AWS_SECRET_ACCESS_KEY={aws_secret_access_key}',
            'myoung34/github-runner:' + image_tag
        ], check=True)
        return jsonify({'status': 'Runner started successfully'}), 200
    except subprocess.CalledProcessError as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
