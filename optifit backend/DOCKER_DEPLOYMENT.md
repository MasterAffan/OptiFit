# Docker Deployment Guide

This guide explains how to deploy the OptiFit Flask backend using Docker and Docker Compose.

## Prerequisites

- Docker installed on your system
- Docker Compose (included with Docker Desktop)
- At least 2GB of available RAM for video processing

## Quick Start

### Using Docker Compose (Recommended)

1. **Navigate to the backend directory:**
   ```bash
   cd "optifit backend"
   ```

2. **Start the service:**
   ```bash
   docker-compose up -d
   ```

3. **Check service status:**
   ```bash
   docker-compose ps
   ```

4. **Test the API:**
   ```bash
   curl http://localhost:5000/ping
   ```

### Using Docker Commands

1. **Build the image:**
   ```bash
   docker build -t optifit-backend .
   ```

2. **Run the container:**
   ```bash
   docker run -d --name optifit-backend -p 5000:5000 optifit-backend
   ```

3. **Check container status:**
   ```bash
   docker ps
   ```

## API Endpoints

Once the container is running, the following endpoints are available:

- **GET /** - Server information and available routes
- **GET /ping** - Health check endpoint
- **POST /upload** - Upload video for squat detection
- **GET /result/<job_id>** - Get processing results
- **GET /processed/<filename>** - Download processed videos

## Configuration

### Environment Variables

The following environment variables can be configured:

- `FLASK_ENV` - Flask environment (default: production)
- `PYTHONUNBUFFERED` - Python output buffering (default: 1)

### Resource Limits

The Docker Compose configuration includes resource limits:
- Memory limit: 2GB
- Memory reservation: 512MB

### Volume Mounts

The following directories are mounted for persistence:
- `./uploads` - Uploaded video files
- `./processed` - Processed video files

## Health Checks

The container includes a health check that:
- Runs every 30 seconds
- Times out after 30 seconds
- Retries 3 times
- Has a 5-second start period

## Troubleshooting

### Container Won't Start

1. **Check logs:**
   ```bash
   docker-compose logs optifit-backend
   ```

2. **Check resource usage:**
   ```bash
   docker stats
   ```

3. **Verify port availability:**
   ```bash
   netstat -tulpn | grep :5000
   ```

### API Not Responding

1. **Check container health:**
   ```bash
   docker ps
   ```

2. **Test health check manually:**
   ```bash
   docker exec optifit-backend curl -f http://localhost:5000/ping
   ```

3. **Check container logs:**
   ```bash
   docker logs optifit-backend
   ```

### Video Processing Issues

1. **Check ffmpeg installation:**
   ```bash
   docker exec optifit-backend ffmpeg -version
   ```

2. **Verify OpenCV and MediaPipe:**
   ```bash
   docker exec optifit-backend python -c "import cv2, mediapipe; print('Dependencies OK')"
   ```

## Production Deployment

### Using Docker Compose

For production deployment, consider:

1. **Update docker-compose.yml:**
   ```yaml
   services:
     optifit-backend:
       restart: always
       environment:
         - FLASK_ENV=production
       deploy:
         resources:
           limits:
             memory: 4G
   ```

2. **Use external volumes:**
   ```yaml
   volumes:
     - /opt/optifit/uploads:/app/uploads
     - /opt/optifit/processed:/app/processed
   ```

3. **Add reverse proxy (nginx):**
   ```yaml
   nginx:
     image: nginx:alpine
     ports:
       - "80:80"
     volumes:
       - ./nginx.conf:/etc/nginx/nginx.conf
   ```

### Security Considerations

1. **Run as non-root user:**
   ```dockerfile
   RUN adduser --disabled-password --gecos '' appuser
   USER appuser
   ```

2. **Use secrets for sensitive data:**
   ```yaml
   secrets:
     - db_password
   ```

3. **Limit container capabilities:**
   ```yaml
   cap_drop:
     - ALL
   cap_add:
     - NET_BIND_SERVICE
   ```

## Monitoring

### Health Monitoring

The container includes built-in health checks. Monitor using:

```bash
# Check container health
docker inspect --format='{{.State.Health.Status}}' optifit-backend

# View health check logs
docker inspect --format='{{range .State.Health.Log}}{{.Output}}{{end}}' optifit-backend
```

### Log Monitoring

```bash
# Follow logs in real-time
docker-compose logs -f optifit-backend

# View recent logs
docker-compose logs --tail=100 optifit-backend
```

### Resource Monitoring

```bash
# Monitor resource usage
docker stats optifit-backend

# Check disk usage
docker exec optifit-backend df -h
```

## Scaling

### Horizontal Scaling

To scale the service:

```bash
# Scale to 3 instances
docker-compose up -d --scale optifit-backend=3
```

### Load Balancing

Use a load balancer (nginx, traefik) to distribute requests across multiple instances.

## Backup and Recovery

### Backup Data

```bash
# Backup uploaded files
tar -czf uploads-backup.tar.gz uploads/

# Backup processed files
tar -czf processed-backup.tar.gz processed/
```

### Restore Data

```bash
# Restore uploaded files
tar -xzf uploads-backup.tar.gz

# Restore processed files
tar -xzf processed-backup.tar.gz
```

## Cleanup

### Stop Services

```bash
# Stop and remove containers
docker-compose down

# Stop and remove containers with volumes
docker-compose down -v
```

### Remove Images

```bash
# Remove unused images
docker image prune

# Remove specific image
docker rmi optifit-backend
```

## Support

For issues related to Docker deployment:

1. Check the logs: `docker-compose logs`
2. Verify system resources: `docker stats`
3. Test API endpoints: `curl http://localhost:5000/ping`
4. Check container health: `docker ps`

## Screenshots

### Successful Docker Build
![Docker Build Success](screenshots/docker-build-success.png)

### Container Running
![Container Running](screenshots/container-running.png)

### API Health Check
![API Health Check](screenshots/api-health-check.png)
