#!/bin/bash
set -e

PACKAGE_FILE="package-lock.json"
if [[ -n "$PLUGIN_PACKAGE_FILE" ]]; then
    PACKAGE_FILE="${PLUGIN_PACKAGE_FILE}"
fi

if [[ -e "${PACKAGE_FILE}" ]]; then
    echo "Using ${PACKAGE_FILE} as cache key"
    CACHE_PATH=$(md5sum "${PACKAGE_FILE}" | cut -d' ' -f1)
    echo "Using ${CACHE_PATH} as cache path"
else
    echo "package file: ${PACKAGE_FILE} not found"
    exit 0
fi

cd $(dirname ${PACKAGE_FILE})
PACKAGE_FILE=$(basename ${PACKAGE_FILE})
npm set cache .npm

SOURCES=(./node_modules ./.npm)

if [[ -n "$PLUGIN_REBUILD" && "$PLUGIN_REBUILD" == "true" ]]; then
    # Create cache
    for source in "${SOURCES[@]}"; do
        if [ -d "$source" ]; then
            echo "Rebuilding tar archive for folder $source..."
            tar cf "/cache/${CACHE_PATH}/${source}.tar" "${source}/"
        elif [ -f "$source" ]; then
            echo "Rebuilding cache for file $source..."
            source_dir=$(dirname $source)
            mkdir -p "/cache/$CACHE_PATH/$source_dir" && \
                rsync -aHA --delete "$source" "/cache/$CACHE_PATH/$source_dir/"
        else
            echo "$source does not exist, removing from cached folder..."
            rm -rf "/cache/$CACHE_PATH/$source"
        fi
    done
elif [[ -n "$PLUGIN_RESTORE" && "$PLUGIN_RESTORE" == "true" ]]; then
    # Restore from cache
    for source in "${SOURCES[@]}"; do
        if [ -d "/cache/${CACHE_PATH}/${source}.tar" ]; then
            echo "Restoring tar archive for folder $source..."
            mkdir -p "$source" && \
                tar xf "/cache/${CACHE_PATH}/${source}.tar"
        elif [ -d "/cache/$CACHE_PATH/$source" ]; then
            echo "Restoring cache for folder $source..."
            mkdir -p "$source" && \
                rsync -aHA --delete "/cache/$CACHE_PATH/$source/" "$source"
        elif [ -f "/cache/$CACHE_PATH/$source" ]; then
            echo "Restoring cache for file $source..."
            source_dir=$(dirname $source)
            mkdir -p "$source_dir" && \
                rsync -aHA --delete "/cache/$CACHE_PATH/$source" "$source_dir/"
        else
            echo "No cache for $source"
        fi
    done
    if [ -d ./node_modules ]
    then
        echo "Running npm install..."
        npm install --no-audit --no-progress --silent
    else
        echo "Running npm clean install..."
        npm ci --no-audit --no-progress --silent
    fi
else
    echo "No restore or rebuild flag specified, plugin won't do anything!"
fi
