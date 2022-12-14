#!/usr/bin/env bash

source ./.env

UBUNTU_VERSION=20.04

NAME=$1
BUCKET_PATH=$2
CLEANUP=${3:-"clean"}

DOCKTOP_HOME=${4:-"$HOME/.docktop"}
SOURCE_BACKUP_PATH="${DOCKTOP_HOME}/amd64_ubuntu${UBUNTU_VERSION}_docktop_$NAME"

if [ "$NAME" == "" ]; then
    echo "Name not set!"

    exit;
fi

if [ "$SOURCE_BACKUP_PATH" == "" ]; then
    echo "Backup path not set!"

    exit;
fi

if [ "$BUCKET_PATH" == "" ]; then
    echo "Bucket path not set!"

    exit;
fi

mkdir ./temp 2>/dev/null

cd ./temp

COMPRESSED_FILE=$NAME.tar.gz
ENCRYPTED_COMPRESSED_FILE=$NAME.tar.gz.gpg

tar -czvf ./$COMPRESSED_FILE $SOURCE_BACKUP_PATH
echo $ENCRYPTION_PASSWORD | gpg --pinentry-mode loopback --symmetric --cipher-algo AES256 --passphrase-fd 0 ./$COMPRESSED_FILE
aws s3 cp ./$ENCRYPTED_COMPRESSED_FILE $BUCKET_PATH --storage-class DEEP_ARCHIVE

if [ "$CLEANUP" == "clean" ]; then
    rm -f ./$COMPRESSED_FILE ./$ENCRYPTED_COMPRESSED_FILE
    cd ..
    rmdir ./temp
fi
