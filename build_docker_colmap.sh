#!/bin/bash
set -e
set -x

#cuda_docker=( "11.8.0"  "11.8.0" "11.8.0"  "11.8.0"  "11.8.0"  "12.1.0" "12.5.1"   )
#pytorch=(     "1.13.1"  "2.0.1"  "2.1.2"   "2.2.2"   "2.3.0"   "2.3.1"  "2.4.0" )
#cuda_conda=(  "11.7"    "11.8"   "11.8"    "11.8"    "11.8"    "12.1"   "12.4"  )

cuda_docker=(  "12.1.1"  ) # "11.8.0" )
pytorch=(      "2.3.1"   ) # "1.13.1"  )
cuda_conda=(   "12.1"    ) # "11.7"   )
python="3.10"

for i in "${!pytorch[@]}"; do
  IMAGE_TAG="py${python}-torch${pytorch[i]}-cu${cuda_conda[i]}"
  echo "$IMAGE_TAG"
  docker build --progress=plain -t dawars/colmap:"${IMAGE_TAG}" \
  --build-arg CUDA_IMAGE_TAG="${cuda_docker[i]}" \
  --build-arg PYTORCH_VERSION="${pytorch[i]}" \
  --build-arg PYTHON_VERSION="${python}" \
  --build-arg CUDA="${cuda_conda[i]}" \
  -f Dockerfile.colmap .

  docker push dawars/colmap:"${IMAGE_TAG}"


done

