#!/bin/bash

# Prompt for Docker Engine or Kaniko choice
read -p "Do you want to use Docker for the build? (yes/y or no/n): " USE_DOCKER

#FILE_PATH=infra/kubernetes

# Convert input to lowercase to handle different cases
USE_DOCKER=$(echo "$USE_DOCKER" | tr '[:upper:]' '[:lower:]')

apply_deployment() {

    # Apply manifests
    echo "Applying manifests..."
    kubectl apply -f .

    # Delete Docker Config JSON
    rm /home/$USER/.docker/config.json > /dev/null 2>&1

}

# Prompt for Docker values (only if using Kaniko)
if [[ "$USE_DOCKER" == "no" || "$USE_DOCKER" == "n" ]]; then
    echo "You have chosen Kaniko."

    # Prompt for Docker values for Kaniko
    read -p "Enter Docker Image Name (e.g., image:tag): " IMAGE_NAME    
    read -p "Enter Docker username: " USERNAME
    read -sp "Enter Docker password: " PASSWORD
    echo
    read -p "Enter Docker email: " EMAIL

    # Create Namespace (only for Kaniko)
    echo "Creating namespace 'owtf'..."
    kubectl create namespace owtf

    # Create Docker registry secret
    echo "Creating Docker registry secret..."
    kubectl create secret docker-registry regcred -n owtf \
      --docker-username="$USERNAME" \
      --docker-password="$PASSWORD" \
      --docker-email="$EMAIL" \
      --docker-server="https://index.docker.io/v1/"

    # Check if namespace creation was successful
    if [ $? -ne 0 ]; then
      echo "Failed to create namespace 'owtf'. Please check your Kubernetes setup and try again."
      exit 1
    fi

    # Check if secret creation was successful
    if [ $? -ne 0 ]; then
      echo "Failed to create Docker registry secret. Please check your inputs and try again."
      exit 1
    fi

    # Replace Image Names
    sed -i "s/--destination=username\/image:tag/--destination=${USERNAME}\/${IMAGE_NAME}/" "owtf-deployment.yaml"
    sed -i "s/image: username\/image:tag/image: ${USERNAME}\/${IMAGE_NAME}/" "owtf-deployment.yaml"

    apply_deployment

    # Reverse the replacement
    sed -i "s/--destination=${USERNAME}\/${IMAGE_NAME}/--destination=username\/image:tag/" "owtf-deployment.yaml"
    sed -i "s/image: ${USERNAME}\/${IMAGE_NAME}/image: username\/image:tag/" "owtf-deployment.yaml"

fi

if [[ "$USE_DOCKER" == "yes" || "$USE_DOCKER" == "y" ]]; then
    echo "You have chosen Docker Engine."

    # Prompt for Docker Image Name
    read -p "Enter Docker Image Name (e.g., image:tag): " IMAGE_NAME
    read -p "Enter Docker username: " USERNAME
    read -sp "Enter Docker password: " PASSWORD
    echo
    read -p "Enter Docker email: " EMAIL

    # Log in to Docker Hub
    echo "Logging in to Docker Hub..."
    echo "$PASSWORD" | docker login -u "$USERNAME" --password-stdin

    # Check if login was successful
    if [ $? -ne 0 ]; then
      echo "Docker login failed. Please check your credentials."
      exit 1
    fi

    # Build the Docker image
    echo "Building Docker image..."
    docker build -t "$USERNAME/$IMAGE_NAME" -f Dockerfile .

    # Check if build was successful
    if [ $? -ne 0 ]; then
      echo "Docker build failed. Please check the Dockerfile and try again."
      exit 1
    fi

    # Push the Docker image to Docker Hub
    echo "Pushing Docker image..."
    docker push "$USERNAME/$IMAGE_NAME"

    # Check if push was successful
    if [ $? -ne 0 ]; then
      echo "Docker push failed. Please check the image name and try again."
      exit 1
    fi

    echo "Docker image $USERNAME/$IMAGE_NAME pushed successfully."

    # Comment InitContainer Block of Kaniko
    echo "Commenting Kaniko Block..."
    sed -i \
        -e '/^spec:/,/^      containers:/ { s/^#.*//; s/^      initContainers:/#      initContainers:/; s/^      - name: kaniko/#      - name: kaniko/; s/^        image: gcr.io\/kaniko-project\/executor:latest/#        image: gcr.io\/kaniko-project\/executor:latest/; s/^        env:/#        env:/; s/^          - name: DOCKER_CONFIG/#          - name: DOCKER_CONFIG/; s/^            value: \/root\/.docker\//#            value: \/root\/.docker\//; s/^        args:/#        args:/; s/^          - "--dockerfile=\/infra\/kubernetes\/Dockerfile"/#          - "--dockerfile=\/infra\/kubernetes\/Dockerfile"/; s/^          - "--context=git:\/\/github.com\/owtf\/owtf#develop"/#          - "--context=git:\/\/github.com\/owtf\/owtf#develop"/; s/^          - "--destination=username\/image:tag"/#          - "--destination=username\/image:tag"/; s/^          - "--compressed-caching=false"/#          - "--compressed-caching=false"/; s/^          - "--ignore-path=\/product_uuid"/#          - "--ignore-path=\/product_uuid"/; s/^        volumeMounts:/#        volumeMounts:/; s/^          - name: kaniko-secret/#          - name: kaniko-secret/; s/^            mountPath: \/root/#            mountPath: \/root/; }' \
        -e '/^      volumes:/,/^      containers:/ { s/^#.*//; s/^      - name: kaniko-secret/#      - name: kaniko-secret/; s/^        secret:/#        secret:/; s/^          secretName: regcred /#          secretName: regcred /; s/^          items:/#          items:/; s/^            - key: .dockerconfigjson/#            - key: .dockerconfigjson/; s/^              path: .docker\/config.json/#              path: .docker\/config.json/; }' \
        owtf-deployment.yaml
    
    # Replace Image Names
    sed -i "s/image: username\/image:tag/image: ${USERNAME}\/${IMAGE_NAME}/" "owtf-deployment.yaml"

    apply_deployment
    
    # Reverse the replacement
    sed -i "s/image: ${USERNAME}\/${IMAGE_NAME}/image: username\/image:tag/" "owtf-deployment.yaml"
    
    #Restore the owtf deployment manifest
    sed -i 's/^#\(.*\)$/\1/' owtf-deployment.yaml

fi
