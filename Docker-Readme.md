### Overview of the Docker Repository for Duolingo Clone

**Repository Name:** `asishgouda/duolingo_clone`

**Description:**
This Docker repository contains a Docker image for the Duolingo Clone project, a Next.js-based application designed to mimic the Duolingo language learning platform. The image is built to provide an easy setup and deployment solution for running the application locally or in any containerized environment.

**Image Details:**
- **Tag:** `v1.0`
- **Base Image:** Node.js 18 (Alpine variant)
- **Configuration:** Includes a self-contained Next.js build with CORS headers configured for API routes.

**Features:**
- **Standalone Build:** Configured with `output: "standalone"` in `next.config.mjs` to ensure a complete and portable application build.
- **Custom Headers:** Includes CORS settings to allow cross-origin requests, which is essential for API interaction.
- **Port Mapping:** The container exposes port 3000, which is mapped to port 3000 on the host machine.

**How to Use:**

1. **Pull the Image:**
   ```bash
   docker pull asishgouda/duolingo_clone:v1.0
   ```

2. **Run the Container:**
   ```bash
   docker run -p 3000:3000 asishgouda/duolingo_clone:v1.0
   ```

3. **Access the Application:**
   Open your web browser and go to `http://localhost:3000` to view the Duolingo Clone application.

**Notes:**
- Ensure Docker is installed and running on your machine before pulling or running the image.
- Adjust port mappings if necessary to avoid conflicts with other applications using port 3000 on your local machine.

This repository provides a streamlined way to deploy and test the Duolingo Clone application using Docker, ensuring consistent environments across different setups.

# Duolingo Clone - Docker Compose Instructions

This document provides instructions for managing and running the Duolingo Clone application using Docker Compose.

## Prerequisites

- Ensure Docker and Docker Compose are installed and running on your machine.
- Adjust port mappings if necessary to avoid conflicts with other applications using port 3000.

## Build and Start Services

To build and start the services using Docker Compose, run:

```bash
docker-compose up --build
```
# Stop and Remove Containers, Networks, and Volumes

To stop the running containers and remove the containers, networks, and any anonymous volumes defined in your Docker Compose setup, run:

```bash
docker-compose down --volumes
```
# Remove All Unused Volumes:
```bash
docker volume prune -f
```
