# PNL Recruitment Challenge

This is my submission for PNL's recruitment challenge available at [AMP-SCZ/coding-test](https://github.com/AMP-SCZ/coding-test/blob/main/bioinform-test.md).

All code related to the challenge is available in the 'notebooks' directory.

# Task 1

## 1.1. Download
The files required to complete the Test were shared via. Dropbox. I'll have to download it to my local machine, using Dropbox's Python SDK.

### Task
Write a script that downloads all the files in the `recruitment_project` folder in Dropbox to a local folder.

### Requirements
- Dropbox Token
  - Generate a token from [Dropbox's App Console](https://www.dropbox.com/developers/apps)
- Dropbox Python SDK
  - `pip install dropbox`

### Downloading the data

```python
import dropbox
import os

TOKEN = <Token goes here>

# Specify the remote and local directory paths
remote_directory_path = "/recruitment_project"
local_directory_path = "/data"


dbx = dropbox.Dropbox(TOKEN)

import os

# Create the local directory if it does not exist
if not os.path.exists(local_directory_path):
    os.makedirs(local_directory_path)

# List all the files in the remote directory
result = dbx.files_list_folder(remote_directory_path)

# Loop over the files and download each one
for entry in result.entries:
    # Get the remote file path
    remote_file_path = entry.path_lower

    # Get the local file path
    local_file_path = os.path.join(local_directory_path, entry.name)

    print(remote_file_path + "  -->  " + local_file_path)

    # Download the file
    metadata , file_content= dbx.files_download(remote_file_path)

    # Write the file content to a local file
    with open(local_file_path, "wb") as f:
        f.write(file_content.content)
```

## 1.2. Anonymize
You are given a file called `data/enroll_data.csv` which contains data about the consent form to participate in a research study. The data contains the following columns, with some sample data:

| site ID | date of consent | cohort | birth date |
|---------|-----------------|--------|------------|
| BWH     | 1/1/2020        | CHR    | 1990-01-01 |
| BWH     | 1/2/2020        | CHR    | 1989-01-02 |
| BWH     | 1/2/2020        | HC     | 1998-01-03 |

### Task

Do the following:
1. Disguise the date of consent to protect their privacy
    - All dates of consent must be earlier than the year 1925. 
    - You must use a random number of days (offset) for each subject so there is no way to trace back.
2. Replace the 'birth date' with the 'age' of the participant at the time of consent.
3. Save the modified CSV as `enroll_data_anon_{your_initials}.csv`. 

### Requirements
- pandas
  - `pip install pandas`

### Anonymizing the data
1. Add age as Column

```python
from datetime import datetime

def calculate_age(dob) -> datetime.date:
    today = datetime.today()
    # calculate the age from a date of birth
    try:
        birthday = dob.replace(year=today.year) # create a new date with the same birthday but current year
    except Exception: # hits exception when encountering invalid dates: eg. Feb 29th of a non leap year
        return today.year - dob.year
    return today.year - dob.year - (birthday > today) # subtract one year if birthday is in the future

df["birth date"] = pd.to_datetime(df["birth date"])
df["age"] = df["birth date"].apply(calculate_age)
```

2. Anonymize the date of consent

```python
df["date of consent"] = pd.to_datetime(df["date of consent"])

import random
import datetime

def days_offset(date1: datetime, date2: datetime) -> int:
    # subtract the dates and get a timedelta object
    delta = date2 - date1
    
    # return the number of days in the timedelta
    return delta.days

def anonymize_date(date: datetime.date) -> datetime.date:
    # get the year, month and day from the input date
    year = date.year
    month = date.month
    day = date.day

    new_year = random.randint(1800, 1925)
    new_month = random.randint(1, 12)
    new_day = random.randint(1, 27)

    return datetime.date(new_year, new_month, new_day)

df["date of consent - anonymized"] = df["date of consent"].apply(anonymize_date)
df["date of consent - anonymized"] = pd.to_datetime(df["date of consent - anonymized"])

df["offset"] = df.apply(lambda row: days_offset(row["date of consent - anonymized"], row["date of consent"]), axis=1)
```

3. Save the modified CSV

```python
anonymized_df = df.drop(columns=['date of consent', 'birth date','offset'])
anonymized_df = anonymized_df.rename(columns = {'date of consent - anonymized':'date of consent'})

anonymized_df.to_csv('/data/enroll_data_anon_DM.csv')

offset_df = df["offset"]

offset_df.to_csv('/data/enroll_data_offset_DM.csv')
```

The resultant CSV files are available at [data/enroll_data_anon_DM.csv](data/enroll_data_anon_DM.csv) and [data/enroll_data_offset_DM.csv](data/enroll_data_offset_DM.csv).

Sample outputs:
1. *enroll_data_anon_DM.csv*

|   | site ID | cohort | age | date of consent |
|---|---------|--------|-----|-----------------|
| 0 | BWH     | CHR    | 33  | 1872-07-15      |
| 1 | BWH     | CHR    | 34  | 1872-03-24      |
| 2 | BWH     | HC     | 25  | 1837-02-15      |
| 3 | BWH     | HC     | 36  | 1816-02-07      |

2. *enroll_data_offset_DM.csv*

|   | offset |
|---|--------|
| 0 | 53860  |
| 1 | 53974  |
| 2 | 66795  |
| 3 | 74474  |


## 1.3. Upload
Upload the anonymized data and the offset to the `recruitment_project` folder in your Dropbox account.

### Task
1. Upload the anonymized data to the `recruitment_project` folder in your Dropbox account.
2. Upload the offset data to the `recruitment_project` folder in your Dropbox account.

### Requirements
- dropbox
  - `pip install dropbox`

### Uploading the data
Files can be uploaded using the following snippet:
    
```python
import dropbox

def dropbox_upload_file(local_file_path, dropbox_file_path, token):
    """
    Upload a file from the local machine to a path in the Dropbox app directory.

    Args:
        local_file_path (str): The path to the local file.
        dropbox_file_path (str): The path to the file in the Dropbox app directory.

    Example:
        dropbox_upload_file('/data/test.csv', '/stuff/test.csv', dropbox_token)

    Returns:
        meta: The Dropbox file metadata.
    """

    try:
        dbx = dropbox.Dropbox(token)

        with open(local_file_path, "rb") as f:
            meta = dbx.files_upload(f.read(), dropbox_file_path, mode=dropbox.files.WriteMode("overwrite"))

            return meta
    except Exception as e:
        print('Error uploading file to Dropbox: ' + str(e))
```

# Task 2

## 2.1. Register Image

Glossary:
- **T1w Image**: T1-weighted image is a type of MRI image that is commonly used to explore brain anatomy because it provides high contrast between gray matter, white matter, and cerebrospinal fluid (CSF). 
- **Atlas Image**: An atlas image is a template image that is used to register other images to. It can be used as a reference to identify structures and functions of the brain. In this case, the atlas image is a T1w image of a brain.
- **Registration**: Registration is the process of aligning two images together. In this case, we want to align the T1w image to the atlas image.

### Task
Register the image `data/given-T1w.nii.gz` to the image `data/atlas-T1w.nii.gz` 

### Narrative(#15-upload-the-csv-file-to-dropbox).
Having little prior experience with MRI images and registrations, I had to do some research to understand the problem and the tools available to solve it. I had to compile a glossary, with terms I had not heard before, to understand the problem. 

I had to read through [ANTs documentation](https://github.com/ANTsX/ANTs), which had an example script detailing the Registration command using different parameters.

### Requirements
- [conda](https://docs.conda.io/en/latest/)
- [ANTs](https://github.com/ANTsX/ANTs)
    - `conda install -c pnlbwh ants`
- Registration script
    - [antsRegistration.sh](antsRegistration.sh) [Source](https://github.com/ANTsX/ANTs/blob/master/Scripts/newAntsExample.sh)

### Registration
The registration script is run using the following command:

```bash
./antsRegistration.sh data/atlas-T1w.nii.gz data/given-T1w.nii.gz fastfortesting
```

## 2.2. Find the volumes of various brain structures

### Task
For all the labels in `data/atlas-integer-labels.nii.gz`, find the volume of the corresponding structure in the output of the registration.

### Narrative
The registration of the image (from 2.1) produced multiple outputs:
- `atlas-T1w_fixed_given-T1w_moving_setting_is_fastfortesting_warped.nii.gz`
- `atlas-T1w_fixed_given-T1w_moving_setting_is_fastfortesting0GenericAffine.mat`
- `atlas-T1w_fixed_given-T1w_moving_setting_is_fastfortesting1Warp.nii.gz`
- `atlas-T1w_fixed_given-T1w_moving_setting_is_fastfortesting1InverseWarp.nii.gz`
- `atlas-T1w_fixed_given-T1w_moving_setting_is_fastfortesting_diff.nii.gz`
- `atlas-T1w_fixed_given-T1w_moving_setting_is_fastfortesting_inv.nii.gz`

Based on the names, each file contains the following:

- `atlas-T1w_fixed_given-T1w_moving_setting_is_fastfortesting_warped.nii.gz`: given T1w image after being warped to match the atlas-T1w image¹.
- `atlas-T1w_fixed_given-T1w_moving_setting_is_fastfortesting0GenericAffine.mat`: affine transform that aligns the given T1w image with the atlas-T1w image¹.
- `atlas-T1w_fixed_given-T1w_moving_setting_is_fastfortesting1Warp.nii.gz`: displacement field that warps the given T1w image to match the atlas-T1w image¹.
- `atlas-T1w_fixed_given-T1w_moving_setting_is_fastfortesting1InverseWarp.nii.gz`: inverse displacement field that warps the atlas-T1w image to match the given T1w image¹.
- `atlas-T1w_fixed_given-T1w_moving_setting_is_fastfortesting_diff.nii.gz`: difference image between the atlas-T1w image and the warped given T1w image².
- `atlas-T1w_fixed_given-T1w_moving_setting_is_fastfortesting_inv.nii.gz`: inverse difference image between the given T1w image and the warped atlas-T1w image².

Source: Conversation with Bing,
1. ANTS Tutorial - Brain/MINDS. https://dataportal.brainminds.jp/ants-tutorial.
2. ANTs/antsRegistrationSyN.sh at master · ANTsX/ANTs · GitHub. https://github.com/ANTsX/ANTs/blob/master/Scripts/antsRegistrationSyN.sh.
3. Anatomy of an antsRegistration call · ANTsX/ANTs Wiki · GitHub. https://github.com/ANTsX/ANTs/wiki/Anatomy-of-an-antsRegistration-call/93d3e24bf32ddf051095d1476c25e861fdf53f3a.
4. ANTs by stnava - GitHub Pages. http://stnava.github.io/ANTs/.
5. Perform registration between two images. — antsRegistration. https://antsx.github.io/ANTsRCore/reference/antsRegistration.html.

Therefore, the `atlas-T1w_fixed_given-T1w_moving_setting_is_fastfortesting_warped.nii.gz` is the image that has been registered to the atlas-T1w image. This is the image that we will use to find the volumes of the various brain structures.

### Requirements
- nibabel
    - `pip install nibabel`

### Solution

```python
# Import libraries
import nibabel as nib
import numpy as np
import pandas as pd

# Load the given T1w image
img = nib.load("/data/result/atlas-T1w_fixed_given-T1w_moving_setting_is_fastfortesting_warped.nii.gz")
img_data = T1_img.get_fdata()

# Load the atlas labels
labels = nib.load("/data/atlas-integer-labels.nii.gz")
labels_data = labels.get_fdata()

# Get the unique labels
roi_labels = np.unique(labels_data)

# Create a dictionary to store the label and volume
label_vol_dict = dict()

# Loop through the labels and calculate the volume
for roi_label in roi_labels:
    # Get the mask for the label
    # The mask is a boolean array, where True represents the voxels that belong to the label
    roi_mask = labels_data == roi_label

    # Multiply the mask with the image data to get the intensity of the voxels that belong to the label
    # We don't care about the intensity, as long as it is non-zero
    roi_intensity = roi_mask * img_data

    # Count the number of non-zero voxels
    # This is the volume of the label
    roi_volume = np.count_nonzero(roi_intensity)

    # Add the label and volume to the dictionary
    label_vol_dict[int(roi_label)] = roi_volume
```

## 2.3. Extract Labels from Text

### Task
From [FreeSurferColorLUT](https://surfer.nmr.mgh.harvard.edu/fswiki/FsTutorial/AnatomicalROI/FreeSurferColorLUT), extract the labels for all the structures in the atlas.

### Solution

```python
# Import libraries
from io import StringIO

FreeSurferColorLUT_data = """
#$Id: FreeSurferColorLUT.txt,v 1.105 2015/07/29 18:23:03 greve Exp $

#No. Label Name:                            R   G   B   A

0   Unknown                                 0   0   0   0
1   Left-Cerebral-Exterior                  70  130 180 0
2   Left-Cerebral-White-Matter              245 245 245 0
3   Left-Cerebral-Cortex                    205 62  78  0

# and so on...
"""

# Class to store the color information
class Color:
    def __init__(self, no, label_name, r, g, b, a):
        self.no = no
        self.label_name = label_name
        self.r = r
        self.g = g
        self.b = b
        self.a = a

    def __str__(self):
        return f"Color({self.no}, {self.label_name}, {self.r}, {self.g}, {self.b}, {self.a})"

# create a file-like object from the string
file = StringIO(FreeSurferColorLUT_data)

colors_dict = dict()

for line in file:
    # skip lines that start with a comment or are empty
    if line.startswith("#") or line.strip() == "":
        continue

    no, label_name, r, g, b, a = line.split()
    
    no = int(no)
    r = int(r)
    g = int(g)
    b = int(b)
    a = int(a)
    
    color = Color(no, label_name, r, g, b, a)
    colors_dict[no] = color
```

## 2.4. Save the Results to a CSV File

### Task
Create a CSV file that contains the following columns:
- `Label No.`
- `Label Name`
- `Volume`

### Requirements
- pandas
    - `pip install pandas`

### Solution

```python
import pandas as pd

df = pd.DataFrame(columns=["Label No.", "Label Name", "Volume"])

for label, volume in label_vol_dict.items():
    values = label, colors_dict[label].label_name, volume
    temp = pd.DataFrame([values], columns=df.columns)
    df = pd.concat([df, temp], ignore_index=True)

df.to_csv('/data/task_2_DM.csv')
```

### Sample Output
|   | Label No. | Label Name                 | Volume  |
|---|-----------|----------------------------|---------|
| 0 | 0         | Unknown                    | 6739657 |
| 1 | 1         | Left-Cerebral-Exterior     | 15644   |
| 2 | 2         | Left-Cerebral-White-Matter | 1500    |
| 3 | 3         | Left-Cerebral-Cortex       | 8851    |

## 2.5. Upload the CSV File to Dropbox

### Task
Upload the CSV file to Dropbox.

Reuse the code from Task 1.3.
