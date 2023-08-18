# MONAI-RACOON

This repo contains utility scripts for inference (weak deployment) with MONAI Label e.g. inside RACOON.

## Usage: `run_monailabel_server.sh`

### MONAI Label server startup
Run this script on a GPU equipped server which has all necessary networking and ports configured to be able to  receive RESTful app requests via HTTP.

The script has the following usage:
```
USAGE
sh run_monailable_server.sh [-p port] [-a appfolder] [-m modelname] [-s studiesfolder] [-h]
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
```

For example, simply running `sh run_monailabel_server.sh` will start a MONAI Label server with `monaibundle` app which can be used to run inference on models from the [MONAI Model Zoo](https://github.com/Project-MONAI/model-zoo) (by default: `wholeBody_ct_segmentation`).
You can change models with the `-m <modelname>` startup parameter, feel free to try the following models:
* [`lung_nodule_ct_detection`](https://github.com/Project-MONAI/model-zoo/tree/dev/models/lung_nodule_ct_detection)
* [`pancreas_ct_dints_segmentation`](https://github.com/Project-MONAI/model-zoo/tree/dev/models/pancreas_ct_dints_segmentation)
* [`prostate_mri_anatomy`](https://github.com/Project-MONAI/model-zoo/tree/dev/models/prostate_mri_anatomy)
* [`renalStructures_UNEST_segmentation`](https://github.com/Project-MONAI/model-zoo/tree/dev/models/renalStructures_CECT_segmentation)
* [`spleen_ct_segmentation`](https://github.com/Project-MONAI/model-zoo/tree/dev/models/spleen_ct_segmentation)
* [`spleen_deepedit_annotation`](https://github.com/Project-MONAI/model-zoo/tree/dev/models/spleen_deepedit_annotation)
* [`swin_unetr_btcv_segmentation`](https://github.com/Project-MONAI/model-zoo/tree/dev/models/swin_unetr_btcv_segmentation)
* [`wholeBody_ct_segmentation`](https://github.com/Project-MONAI/model-zoo/tree/dev/models/wholeBody_ct_segmentation)
* [`wholeBrainSeg_Large_UNEST_segmentation`](https://github.com/Project-MONAI/model-zoo/tree/dev/models/wholeBrainSeg_Large_UNEST_segmentation)

### Inference requests
Once the server is up and running, you can send inference requests from any endpoint via REST API, e.g. from a laptop or a thin client in the clinic.

For example, the following call will run inference on a local 3D image `/path/to/volume.nii.gz` and produce the segmentation output `/path/to/volume_labelmap.nii.gz` 
(assuming server address `127.0.0.1:8000`, `monaibundle` app and `wholeBody_ct_segmentation` model):
```bash
curl -X 'POST' \
  'http://127.0.0.1:8000/infer/wholeBody_ct_segmentation?output=image' @ \
  -H 'accept: application/json' \
  -H 'Content-Type: multipart/form-data' \
  -F 'params={}' \
  -F 'file=@/path/to/volume.nii.gz;type=application/gzip' \
  -F 'label=' \
  --output '/path/to/volume_labelmap.nii.gz'
```

### Further notes
Instead of REST API calls from CLI, you can also connect to the already running server instance with medical image viewers like 3D Slicer or OHIF.
Visit [MONAI Label's "Supported Viewers" documentation](https://github.com/Project-MONAI/MONAILabel/tree/main#step-3-monai-label-supported-viewers) for more information.

