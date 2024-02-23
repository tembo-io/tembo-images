# tembo-images
Docker images for Postgres

## Table of Contents
- [Requirements](#requirements)
- [How to Create Custom Stack Image and Test Locally](#how-to-create-custom-stack-image-and-test-locally) 
- [How to Publish Custom Stack Image to Quay and AWS ECR](#how-to-publish-custom-stack-image-to-quay-and-aws-ecr)
- [How to Apply Custom Image to an Existing Stack](#how-to-apply-custom-image-to-an-existing-stack)

## Requirements
- rust
- kind
- just

## How to Create Custom Stack Image and Test Locally
### 1. Ensuring a proper setup
#### Create directory and files
Within your local developer environment, start by creating a new directory for your custom image. Note that current naming conventions are to abbreviate the Stack title and add a -cnpg tag, for example:
    - `dw-cnpg` represents the custom container image for the Data Warehouse Stack
    - `geo-cnpg` for the Geospatial Stack
    - `ml-cnpg` for the Machine Learning Stack
```
mkdir <your-image-name>
```

From within the newly-created directory, you can then create a `Cargo.toml` and `Dockerfile`.
```
touch Cargo.toml Dockerfile
```

#### Check local docker registery
When the image is eventually built once `docker build` is invoked (a couple steps from this point), the resultant container is stored within a local docker registry.
To allow for a fresh workspace, it's good practice to check whether there are any register containers currently running, and if so, to stop and remove them.
The following commands can help you achieve that:
```
docker ps
```
```
docker stop <registry-container-id>
```
```
docker rm <registry-container-id>
```

The registry can then be started via the following:
```
docker run -d -p 5000:5000 --restart=always --name registry registry:2
```

### 2. The Cargo.toml file
The contents of the Cargo.toml file are metadata to a given image, including name and description.
This information can be readily found by refering to an already published image, for example [geo-cnpg](https://github.com/tembo-io/tembo-images/blob/main/geo-cnpg/Cargo.toml) and adapted to your new image.

### 3. The Dockerfile
Composing the Dockerfile is relatively more involved, but nevertheless straightforward.
The Dockerfile contains all the instructions necessary for Docker to build your image, including, but not limited to `runtime dependencies` and steps to `compiling Postgres extensions` from source.
Defining dependencies in a Stack-specific image is important to emphasize, as it helps reduce bloat of the commonly-leveraged standard-cnpg image.
You're invited to visit the Dockerfiles from the different images in this repository for inspiration.

### 4. Building the image
At this stage you're ready to build the image. 
```
docker build -t localhost:5000/my-custom-image:15-0.0.1 .
```
Bear in mind what each part of this command is doing, as this may help you adapt to your specific situation if necessary:
- `docker`:
- `build`:
- `-t`: The `t` flag is an option that allows you to apply a tag to the image.
- `localhost:5000`:
- `my-custom-image`:
- `15-0.0.1`:
- `.`: The period `.` represents executing the given command within the current directory. If you'd prefer to include a file path, feel free to replace this period `.` with your path. 

### 5. Pushing the newly-created image to your local docker registry
```
docker push localhost:5000/my-custom-image:15-0.0.1
```
NOTE: At this stage it takes some moments for the proper image to appear in docker images. Still going through final troubleshooting, but might also require:
docker build -t my-custom-postgis-image:15-0.0.5 .
docker push my-custom-postgis-image:15-0.0.5

The following command allows you to confirm a successful push:
```
docker images
```

### 6. Applying custom image to a yaml file to prepare for upcoming `kubectl apply` command
For the purposes of these instructions, we will utilize the `sample-standard.yaml` file, found at /tembo/tembo-operator/yaml/sample-standard.yaml
Using your preferred IDE or text editor, update the line that defines the image:
```
image: my-custom-image:15-0.0.1
```
### 7. Running the Tembo Operator locally
If you haven't already, clone the tembo repository to your local machine and navigate to the tembo-operator directory.
```
git clone https://github.com/tembo-io/tembo.git
```
```
cd tembo/tembo-operator
```
Once there, run the following to start the Tembo Operator:
```
just start-kind
```
```
just run
```

### 8. Connecting your local docker registry and kind kubernetes cluster
```
kind load docker-image my-custom-image:15-0.0.1
```
```
kubectl apply -f yaml/sample-standard.yaml
```
To check for success, run:
```
kubectl get pods
```
### 9. Enter pod for further testing and exploration
```
kubectl exec -it sample-standard-1 -- /bin/bash
```

## How to Publish Custom Stack Image to Quay and AWS ECR
TODO

## How to Apply Custom Image to an Existing Stack
TODO

