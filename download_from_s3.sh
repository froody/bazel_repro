#!/bin/bash

# This script downloads a directory from S3 and packages it up as a tarball.

set -e -o pipefail

USAGE="\nUsage: $0 <mode> <s3_uri> <dest_file>\n\n\t<s3_uri> - the S3 URI to download \
from\n\t<dest_file> - the destination file to create (should end with .tar.gz)\
\n\nExample: $0 TARGZ s3://my-bucket/my-model/ model-data.tar.gz\n
\n\nExample: $0 FILE s3://my-bucket/my_file.txt my_file.txt\n"

# warn user if AWS creds are missing
# assert that the args are not empty
if [ -z "$AWS_PROFILE" ] && [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo -e "WARNING: enviroment variables for AWS credentials not set. You\
 may need to set either AWS_PROFILE (after SSO login) or AWS_REGION,\
 AWS_ACCESS_KEY_ID, and AWS_SECRET_ACCESS_KEY (for access via key credentials)" >&2
fi

if [ "$#" -ne 3 ]; then
    echo -e "$USAGE"
    exit 1
fi

MODE=$1
S3_URI="$2"
DEST_FILE="$(realpath -m "$3")"

# Validate the arguments
if [[ $MODE != "TARGZ" && $MODE != "FILE" ]]; then
    echo "Mode must be either TARGZ or FILE"
    echo -e "$USAGE"
    exit 1
fi
if [ -z "$S3_URI" ]; then
    echo "S3 URI is required"
    echo -e "$USAGE"
    exit 1
fi
if [ -z "$DEST_FILE" ]; then
    echo "Destination directory is required"
    echo -e "$USAGE"
    exit 1
fi

# localized per-user, but system-wide, and bazel builds use restrictive file
# permisssions. Therefore $TMPDIR is unreliable and prone to permissions errors
# linux+MacOS tempdir handling code from:
# https://unix.stackexchange.com/questions/30091/fix-or-alternative-for-mktemp-in-os-x
# (MacOS version of mktemp requires -t flag, different from Linux -t flag)
TMPDIR="$(mktemp -d 2>/dev/null || mktemp -d -t 'download_s3_dir.XXXXXX')"
trap 'rm -rf "$TMPDIR"' EXIT
DEST_DIR="$TMPDIR/$(basename "$DEST_FILE")/data"

# add a helpful message in case the user forgets to SSO first
function error_handler() {
  CMD="$@"
  echo -e "\nERROR: Command: '$CMD' failed You may need to run 'aws sso login --profile=$AWS_PROFILE' to refresh your AWS S3 credentials\n"  >&2
  aws configure list >&2
  exit 127
}

# download the model
if [[ $MODE == "TARGZ" ]]; then
  mkdir -p "$DEST_DIR"
  CMD=( aws s3 cp --recursive "$S3_URI" "$DEST_DIR" )
  "${CMD[@]}" || error_handler "${CMD[@]}"
  # tarball the model folder
  mkdir -p "$(dirname "$DEST_FILE")"
  tar -czvf "$DEST_FILE" --directory="$(dirname "$DEST_DIR")" data/
else
  CMD=( aws s3 cp "$S3_URI" "$DEST_FILE" )
  "${CMD[@]}" || error_handler "${CMD[@]}"
fi

# done
