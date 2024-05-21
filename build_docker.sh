#!/bin/bash
set -e
set -x

#cuda_docker=( "11.8.0"  "11.8.0" "11.8.0"  "11.8.0"  "11.8.0" )
#pytorch=(     "1.13.1"  "2.0.1"  "2.1.2"   "2.2.2"   "2.3.0"  )
#torchvision=( "0.14.1"  "0.15.2" "0.16.2"  "0.17.2"  "0.18.0" )
#cuda_conda=(  "11.7"    "11.8"   "11.8"    "11.8"    "11.8"   )

cuda_docker=(  "11.8.0" "11.8.0" )
pytorch=(      "2.3.0"  "1.13.1"  )
torchvision=(  "0.18.0" "0.14.1" )
cuda_conda=(   "11.8"   "11.7"   )

for i in "${!pytorch[@]}"; do
  IMAGE_TAG="torch${pytorch[i]}-cu${cuda_conda[i]}"
  echo "$IMAGE_TAG"
  docker build --progress=plain -t dawars/pytorch:"${IMAGE_TAG}" \
  --build-arg CUDA_IMAGE_TAG="${cuda_docker[i]}" \
  --build-arg PYTORCH_VERSION="${pytorch[i]}" \
  --build-arg TORCHVISION_VERSION="${torchvision[i]}" \
  --build-arg CUDA="${cuda_conda[i]}" \
  -f Dockerfile.pytorch .


#  docker build --progress=plain -t dawars/sdfstudio:${IMAGE_TAG} \
#  --build-arg CUDA_IMAGE_TAG="${cuda_docker[i]}" \
#  --build-arg PYTORCH_VERSION="${pytorch[i]}" \
#  --build-arg TORCHVISION_VERSION="${torchvision[i]}" \
#  --build-arg CUDA="${cuda_conda[i]}" \
#  -f Dockerfile.sdfstudio .
#  docker push dawars/sdfstudio:${IMAGE_TAG}

  docker build --progress=plain -t dawars/3dbuildings:${IMAGE_TAG} \
  --build-arg CUDA_IMAGE_TAG="${cuda_docker[i]}" \
  --build-arg PYTORCH_VERSION="${pytorch[i]}" \
  --build-arg TORCHVISION_VERSION="${torchvision[i]}" \
  --build-arg CUDA="${cuda_conda[i]}" \
  -f Dockerfile.3dbuildings .
  docker push dawars/pytorch:${IMAGE_TAG}
  docker push dawars/3dbuildings:${IMAGE_TAG}

done

