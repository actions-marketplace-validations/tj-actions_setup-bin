#!/usr/bin/env bash

set -eou pipefail

TMPDIR=$(mktemp -d)

if [[ "$INPUT_VERSION" == "latest" ]]; then
  echo "Downloading the latest release"
  # Set the latest release version
  VERSION=$(curl --silent -H "Authorization: token $INPUT_TOKEN" "https://api.github.com/repos/$INPUT_REPOSITORY_OWNER/$INPUT_REPOSITORY/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
else
  echo "Downloading version $INPUT_VERSION"
  VERSION=$INPUT_VERSION
fi

# Determine the operating system and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

if [[ $OS == "darwin" ]]; then
  FILENAME="$INPUT_REPOSITORY_${VERSION}_Darwin_x86_64.tar.gz"
  URL="https://github.com/$INPUT_REPOSITORY_OWNER/$INPUT_REPOSITORY/releases/download/${VERSION}/${FILENAME}"
  SHA256SUM_FILE="checksums.txt"
  SHA256SUM_URL="https://github.com/$INPUT_REPOSITORY_OWNER/$INPUT_REPOSITORY/releases/download/${VERSION}/${SHA256SUM_FILE}"
elif [[ $OS == "linux" ]]; then
  if [[ $ARCH == "x86_64" ]]; then
    FILENAME="$INPUT_REPOSITORY_${VERSION}_Linux_x86_64.tar.gz"
    URL="https://github.com/$INPUT_REPOSITORY_OWNER/$INPUT_REPOSITORY/releases/download/${VERSION}/${FILENAME}"
    SHA256SUM_FILE="checksums.txt"
    SHA256SUM_URL="https://github.com/$INPUT_REPOSITORY_OWNER/$INPUT_REPOSITORY/releases/download/${VERSION}/${SHA256SUM_FILE}"
  else
    echo "Unsupported architecture: $ARCH"
    exit 1
  fi
elif [[ $OS == "windows" ]]; then
  if [[ $ARCH == "x86_64" ]]; then
    FILENAME="$INPUT_REPOSITORY_${VERSION}_Windows_x86_64.zip"
    URL="https://github.com/$INPUT_REPOSITORY_OWNER/$INPUT_REPOSITORY/releases/download/${VERSION}/${FILENAME}"
    SHA256SUM_FILE="checksums.txt"
    SHA256SUM_URL="https://github.com/$INPUT_REPOSITORY_OWNER/$INPUT_REPOSITORY/releases/download/${VERSION}/${SHA256SUM_FILE}"
  else
    echo "Unsupported architecture: $ARCH"
    exit 1
  fi
else
  echo "Unsupported operating system: $OS"
  exit 1
fi

# Download the binary and its checksum file to the temporary directory
curl --silent -H "Authorization: token $INPUT_TOKEN" --location --remote-name --output $TMPDIR/$FILENAME $URL
curl --silent -H "Authorization: token $INPUT_TOKEN" --location --remote-name --output $TMPDIR/$SHA256SUM_FILE $SHA256SUM_URL

# Verify the checksum
EXPECTED=$(grep "$FILENAME" $TMPDIR/$SHA256SUM_FILE | awk '{print $1}')
ACTUAL=$(sha256sum $TMPDIR/$FILENAME | awk '{print $1}')
if [[ "$EXPECTED" != "$ACTUAL" ]]; then
  echo "Checksum verification failed"
  exit 1
fi

# Extract the binary in the temporary directory
if [[ $OS == "darwin" ]]; then
  tar -xzf $TMPDIR/$FILENAME -C $TMPDIR
elif [[ $OS == "linux" ]]; then
  tar -xzf $TMPDIR/$FILENAME -C $TMPDIR
elif [[ $OS == "windows" ]]; then
  unzip $TMPDIR/$FILENAME -d $TMPDIR
else
  echo "Unsupported operating system: $OS"
  exit 1
fi

# Make the binary executable
chmod +x $TMPDIR/$INPUT_REPOSITORY

# Return the binary path
echo "binary_path=$TMPDIR/$INPUT_REPOSITORY" >> $GITHUB_OUTPUT