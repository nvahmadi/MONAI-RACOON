#!/usr/bin/env bash

usage="
$(basename "$0")

USAGE
sh $(basename $0) [-p port] [-a appfolder] [-m modelname] [-s studiesfolder] [-h]
Arguments
    -p <port>
        Port on which MONAI Label server will listen for requests
        Defaults to port <8000>.
    -a <appfolder>
        Folder of MONAI Label app (e.g. radiology, monaibundle)
        If no app folder is given, this script's folder location will be assumed as <current_working_directory>,
           and MONAI Label --app parameter will be set to <current_working_directory>/monaibundle.
        If monaibundle app folder does not yet exist in <current_working_directory>, it will be downloaded.
    -m <modelname>
        Name of model to use. 
        If not given, defaults to <segmentation> model.
        If not given, and the app is set to <monaibundle>, default to <wholeBody_ct_segmentation> (TotalSegmentator bundle).
    -s <studiesfolder>
        Studies folder, i.e. folder with image data.
        Folder can be empty.
        If not given, default to <current_working_directory>/data (will be created if not existent).
    -h
        Print this help.  
"

# Get CWD of this script (script argument $0):
#    - if no app folder is given (argument $1), the monaibundle app of MONAI Label will be downloaded into this folder
SCRIPT=$(readlink -f "$0")
BASEDIR=$(dirname "$SCRIPT")
MONAIBUNDLE_APP_DIR=$BASEDIR/monaibundle

while getopts ":p:a:m:s:h" opt; do
  case $opt in
    p) port="$OPTARG" ;;
    a) app="$OPTARG" ;;
    m) model="$OPTARG" ;;
    s) studies="$OPTARG" ;;
    h) echo "$usage" >&2
       exit 1 ;;
    \?) echo "Invalid option -$OPTARG" >&2 ;;
  esac
done

#######################################
# Fill default values for all arguments
# default port
port=${port:-8000}

# default app: monaibundle (download if not available yet)
app=${app:-$MONAIBUNDLE_APP_DIR}
if [ -d "$app" ]; then
    echo "MONAI Label app folder found ('$app')."
else
    echo "MONAI Label app folder not found. Downloading default app (monaibundle) to script parent folder."
    docker run --rm \
        --gpus all \
        -v $BASEDIR:/workdir \
        --network=host \
        --ipc=host \
        projectmonai/monailabel:0.7.0 \
        /bin/bash -c "monailabel apps --download --name monaibundle --output /workdir"
    echo "MONAI Label app folder downloaded."
fi

# default model:
appname=$(basename "$app")
if [ "$appname" = "monaibundle" ]; then
    default_model="wholeBody_ct_segmentation"
else
    default_model="segmentation"
fi
model=${model:-$default_model}

# default studies folder with data (create if does not exist, can be empty)
studies=${studies:-"$BASEDIR/studies"}
mkdir -p $studies


#######################################
# Startup MONAI Label server
echo "Starting server:"
docker run --rm \
    --gpus all \
    --shm-size=1g \
    --ulimit memlock=-1 \
    --ulimit stack=67108864 \
    -v $app:/workdir/app \
    -v $studies:/workdir/studies \
    --network=host \
    --ipc=host \
    projectmonai/monailabel:0.7.0 \
    /bin/bash -c "monailabel start_server \
        --app /workdir/app \
        --studies /workdir/studies \
        --port $port \
        --conf models $model"

# Command to make an inference request to the server  on a new volume
# (assuming <localhost>:8000 and ./monaibundle/wholeBody_ct_segmentation model)
: '
curl -X 'POST' \
  'http://127.0.0.1:8000/infer/wholeBody_ct_segmentation?output=image' @ \
  -H 'accept: application/json' \
  -H 'Content-Type: multipart/form-data' \
  -F 'params={}' \
  -F 'file=@/path/to/volume.nii.gz;type=application/gzip' \
  -F 'label=' \
  --output '/path/to/volume_labelmap.nii.gz'
 '
 