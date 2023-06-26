# drone-npm-cache

This is a pure Bash [Drone](https://github.com/drone/drone) plugin to cache npm downloads to a locally mounted volume

## Docker
Build the docker image by running:

```bash
docker build --rm=true -t movio/drone-npm-cache .
```

## Usage
Execute from the working directory:

```bash
docker run --rm \
  -e PLUGIN_REBUILD=true \
  -e PLUGIN_MOUNT="./node_modules" \
  -e DRONE_REPO_OWNER="foo" \
  -e DRONE_REPO_NAME="bar" \
  -e DRONE_JOB_NUMBER=0 \
  -v $(pwd):$(pwd) \
  -v /tmp/cache:/cache \
  -w $(pwd) \
  movio/drone-npm-cache
```
