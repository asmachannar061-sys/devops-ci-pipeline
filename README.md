# DevOps CI Pipeline

A small Python HTTP service used to demonstrate a Jenkins pipeline that runs tests, analyzes code with SonarQube, and builds a Docker image.

## What this repository contains

- `scripts/install-docker.sh` — installs Docker Engine and the Compose plugin on Debian or Ubuntu.
- `docker-compose.yml` — runs Jenkins and SonarQube with PostgreSQL, persistent volumes, and a private bridge network.
- `Jenkinsfile` — checks out the repository, runs tests, scans with SonarQube, and builds the application image.
- `app.py`, `tests/`, and `Dockerfile` — sample application, tests, and multi-stage image build.

## Run the services on Linux

Use an Ubuntu or Debian Linux machine with `git`, `curl`, and `sudo`. The install script needs root privileges:

```bash
git clone https://github.com/asmachannar061-sys/devops-ci-pipeline.git
cd devops-ci-pipeline
git switch feature/jenkins-sonarqube-docker
sudo bash scripts/install-docker.sh
```

Log out and back in after installation if you want to use Docker without `sudo`. The script adds the invoking user to the `docker` group; membership in that group grants root-equivalent access to the machine.

SonarQube needs a higher Linux memory-map limit. Set it before starting the stack:

```bash
sudo sysctl -w vm.max_map_count=524288
```

Set a private PostgreSQL password in a local, untracked `.env` file and pass the Docker socket's group ID to Compose:

```bash
cp .env.example .env
# Edit .env and replace the example password with a strong value.
export DOCKER_GID="$(stat -c '%g' /var/run/docker.sock)"
docker compose up -d --build
```

The `docker-compose.yml` binds the Docker socket into Jenkins so pipeline builds use the host Docker Engine. This is convenient for a local lab but grants Jenkins control over that Engine; use an isolated machine and do not expose this setup to untrusted users.

Open Jenkins at <http://localhost:8080> and SonarQube at <http://localhost:9000>. Wait for SonarQube to finish starting before running the pipeline. Get Jenkins's initial administrator password with:

```bash
docker compose exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

Persistent Docker volumes retain Jenkins data, SonarQube data/extensions/logs, and PostgreSQL data when containers are recreated. The Compose bridge network lets the Jenkins and SonarQube containers reach each other by service name (`sonarqube`); the host ports make their web interfaces available locally.

## Configure Jenkins and SonarQube once

1. Complete Jenkins's first-time setup. The Jenkins image preinstalls the Pipeline, Git, and SonarQube Scanner plugins.
2. In SonarQube, sign in, create a user token, and copy it.
3. In Jenkins, add a **Secret text** credential with ID `sonarqube-token` containing that token.
4. In **Manage Jenkins → System**, add a SonarQube installation named `SonarQube` with server URL `http://sonarqube:9000` and select the `sonarqube-token` credential.
5. In **Manage Jenkins → Tools**, add a SonarQube Scanner installation named `SonarScanner` (enable automatic installation).
6. Create a Jenkins **Pipeline** job, choose **Pipeline script from SCM**, select Git, and enter this repository URL and the branch `feature/jenkins-sonarqube-docker`. For a private GitHub repository, configure a GitHub access token as Jenkins SCM credentials.
7. Save and run the job. The pipeline checks out the branch, runs unit tests in the Docker build's test stage, runs SonarQube analysis, and builds `devops-ci-pipeline:<build-number>`.

The scanner tool name and SonarQube server name must match the names used in `Jenkinsfile`. The project key and source/test paths are in `sonar-project.properties`.

## Run the sample locally

```bash
python -m unittest discover -s tests -v
docker build --tag devops-ci-pipeline:local .
docker run --rm -p 8000:8000 devops-ci-pipeline:local
```

Visit <http://localhost:8000/health>; the service responds with `{"status": "ok"}`.

Stop the stack with `docker compose down`. To also erase its persisted data, use `docker compose down --volumes` (this permanently removes the named data volumes).

## Commit and publish your assignment branch

From the repository on your computer, commit and push the files to GitHub:

```bash
git switch feature/jenkins-sonarqube-docker
git add .
git commit -m "Add Jenkins and SonarQube CI pipeline"
git push -u origin feature/jenkins-sonarqube-docker
```

The Docker installation script is for a Debian/Ubuntu Linux host; it is not intended to install Docker on Windows. The Compose stack and pipeline should be run on a Linux machine with Docker available.
