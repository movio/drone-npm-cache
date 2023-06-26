#!/bin/bash
set -e

if [ -z "$PLUGIN_MOUNT" ]; then
    echo "Specify folders to cache in the mount property! Plugin won't do anything!"
    exit 0
fi

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

IFS=','; read -ra SOURCES <<< "$PLUGIN_MOUNT"
if [[ -n "$PLUGIN_REBUILD" && "$PLUGIN_REBUILD" == "true" ]]; then
    # Create cache
    for source in "${SOURCES[@]}"; do
        if [ -d "$source" ]; then
            echo "Rebuilding cache for folder $source..."
            mkdir -p "/cache/$CACHE_PATH/$source" && \
                rsync -aHA --delete "$source/" "/cache/$CACHE_PATH/$source"
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
        if [ -d "/cache/$CACHE_PATH/$source" ]; then
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
else
    echo "No restore or rebuild flag specified, plugin won't do anything!"
fi
