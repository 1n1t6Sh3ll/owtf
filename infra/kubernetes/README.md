## OWTF Kubernetes Deployment ##

These are the instructions for deploying the OWTF (Offensive Web Testing Framework) project using Kubernetes. The deployment process includes options for building Docker images either using Docker Engine or Kaniko.

### Prerequisites ###

Kubernetes Cluster: Ensure you have a running Kubernetes cluster using [Kind](https://kind.sigs.k8s.io/), [Minikube](https://minikube.sigs.k8s.io/docs/start/) or CSP Managed like EKS, AKE etc.

Kubectl: Make sure [kubectl](https://kubernetes.io/docs/tasks/tools/) is installed and configured to interact with your Kubernetes cluster.

Docker: Required if you choose to use [Docker Engine](https://docs.docker.com/engine/install/) or [Kaniko](https://github.com/GoogleContainerTools/kaniko) for building Docker images.

Storage: As we will be building and storing images and data associated with them, please make sure you have 30 GB of space (excluding OS occupied space)

1. **Using Kind Cluster**

    + Create a Kind cluster using these commands - 

            cat <<EOF | kind create cluster --config=-
            kind: Cluster
            apiVersion: kind.x-k8s.io/v1alpha4
            nodes:
            - role: control-plane
            kubeadmConfigPatches:
            - |
                kind: InitConfiguration
                nodeRegistration:
                kubeletExtraArgs:
                    node-labels: "ingress-ready=true"
            extraPortMappings:
            - containerPort: 80
                hostPort: 80
                protocol: TCP
            - containerPort: 443
                hostPort: 443
                protocol: TCP
            EOF

    + Install Nginx Ingress Controller
            
            kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

        The manifest include kind-specific patches that schedule it to the custom-labeled node, set taint tolerations, and forward hostPorts to the ingress controller.

        Hold off until it's ready to start processing requests. Once done, the Ingress is now fully configured. 
        
            kubectl wait --namespace ingress-nginx \
            --for=condition=ready pod \
            --selector=app.kubernetes.io/component=controller \
            --timeout=90s

2. **Using Minikube Cluster**
    
    + Visit Minikube Official site to install [Minikube](https://minikube.sigs.k8s.io/docs/start/)
    + Select you OS and proceed with installtion steps.
    + Once installed, Start your minikube cluster
            
            minikube start --driver=docker
    + Verfiy components of your minikube cluster

            kubectl get all -A
    + Install Nginx Ingress Addon

            minikube addons enable ingress
    + Configure your local environment to use docker daemon inside minikube cluster

            eval $(minikube docker-env)


### Deployment Steps ###

1. **Clone the Repository**

    First, clone the repository containing the deployment script and Kubernetes manifests:

        git clone https://github.com/owtf/owtf.git

        cd owtf/infra/kubernetes

2. **Execute the Deployment Script**

    Run the deployment script and follow the prompts to deploy OWTF. The script will guide you through using either Docker Engine or Kaniko for building Docker images.

        bash deploy-script.sh

    **Using Docker Engine**

    When prompted, enter **yes** or **y** to use Docker Engine for building    Docker images, Provide the Docker image name, username, password, and email when requested.
    
    Credentials has to be created by creating an account on [Docker hub](https://hub.docker.com/).
    
    The script will:

    * Log in to Docker Hub.
    * Build the Docker image.
    * Push the Docker image to Docker Hub.
    * Apply Kubernetes manifests.

    **Using Kaniko**

    When prompted, enter **no** or **n** to use Kaniko for building Docker images.
    Provide the Docker image name, username, password, and email when requested.
    The script will:
    * Create a Kubernetes namespace named owtf.
    * Create a Docker registry secret.
    * Update the Kubernetes manifest for the deployment.
    * Apply Kubernetes manifests.

3. **Verify Deployment**

    After the script completes, verify that the OWTF application is running correctly in your Kubernetes cluster:

        kubectl get all -n owtf

    Post deployment, your owtf namespace should look like this

        NAME                       READY   STATUS     RESTARTS   AGE
        pod/db-7d977c56f4-w7zm6    1/1     Running    0          10s
        pod/owtf-95fd8c8f8-gt9dv   0/1     Init:0/1   0          10s

        NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                                        AGE
        service/owtf-service   LoadBalancer   10.96.228.247   <pending>     8008:31540/TCP,8010:31799/TCP,8009:32392/TCP   9s
        service/postgres       ClusterIP      10.96.89.225    <none>        5432/TCP                                       10s

        NAME                   READY   UP-TO-DATE   AVAILABLE   AGE
        deployment.apps/db     1/1     1            1           10s
        deployment.apps/owtf   0/1     1            0           10s

        NAME                             DESIRED   CURRENT   READY   AGE
        replicaset.apps/db-7d977c56f4    1         1         1       10s
        replicaset.apps/owtf-95fd8c8f8   1         1         0       10s

    To access you application, run this command to get ingress.

        kubectl get ingress -n owtf

    It should look like this, Address will change depending upon the Cluster.

        NAMESPACE   NAME           CLASS    HOSTS   ADDRESS     PORTS   AGE
        owtf        owtf-ingress   <none>   *       localhost   80      10s

    To access your owtf pod logs, run this command

    > Note: If your have not configured SMTP for your OWTF application, use logs of owtf pod and get the verification link during login. Make sure to replace approriate IP address in that link with Ingress Address.

        kubectl logs <pod name of owtf deployement> -n owtf

    If you are using **Kaniko**, run this command to get logs 

    + For owtf pod

            kubectl logs <pod name of owtf deployement> -n owtf -c owtf
    + For kaniko pod

            kubectl logs <pod name of owtf deployement> -n owtf -c kaniko 

For any questions or support, Please raise a github issue.
