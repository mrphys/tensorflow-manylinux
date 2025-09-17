# Run like this in terminal ./build_bash.sh

# Build base image
docker build -t ghcr.io/mrphys/tensorflow-manylinux-base:latest -f Dockerfile.base .

# Build for each Python version
# 
for PY in 3.9 3.10 3.11 3.12; do
    docker build \
      --build-arg PY_VERSION=$PY \
      -t ghcr.io/mrphys/tensorflow-manylinux:py$PY \
      -f Dockerfile.py .
    docker push ghcr.io/mrphys/tensorflow-manylinux:py$PY
done


# --no-cache \
