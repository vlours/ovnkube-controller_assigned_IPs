# check_assigned_ips.sh

## Description

This bash script will display the OVN PODs' information from the ovn-controller container for a desired period of time.

The script has the following dependencies:

- `jq`
  - To download on Linux: `yum install jq`
  - To download on MacOS: `brew install jq`

## Usage

### Basic Usage

Simply run the script with the desired option(s)

```bash
usage: check_assigned_ips.sh -n <nodename>|-p <pod_name> -s <YYYY-mm-ddTHH> -e <YYYY-mm-ddTHH> [-o csv|json] [-S startTime|podName|podIP|podMac|stopTime] [-h]
```

### Script Options

```text
usage: check_assigned_ips.sh -n <nodename>|-p <pod_name> -s <YYYY-mm-ddTHH> -e <YYYY-mm-ddTHH> [-o csv|json] [-S startTime|podName|podIP|podMac|stopTime] [-h]

|--------------------------------------------------------------------------------------------------------|
| Options | Description                                                                      | [Details] |
|---------|----------------------------------------------------------------------------------|-----------|
|      -n | set the related nodename to find the related POD                                 |           |
|      -p | use a PODNAME instead of the nodename                                            |           |
|      -s | defined the start of the timeframe (UTC) in a format 'YYYY-mm-ddTHH'             |           |
|      -e | defined the end of the timeframe (UTC)in a format 'YYYY-mm-ddTHH' (not included) |           |
|      -o | provide the output in a 'csv' or 'json' format                                   |           |
|      -S | Sort by 'startTime', 'podName', 'podIP', 'podMac', 'stopTime'                    | startTime |
|---------|----------------------------------------------------------------------------------|-----------|
|         | Examples:                                                                        |           |
|         |  - for a timeframe starting on 2025 August 9th at 10 am: '-s 2025-08-09T10'      |           |
|         |  - for a timeframe ending on 2025 August 9th at 01 pm: '-e 2025-08-09T13'        |           |
|---------|----------------------------------------------------------------------------------|-----------|
|         | Additional Options:                                                              |           |
|---------|----------------------------------------------------------------------------------|-----------|
|      -h | display this help and check for updated version                                  |           |
|--------------------------------------------------------------------------------------------------------|

Current Version: X.Y.Z
```

### Examples

- Display the OVN information POD created between the `2025-07-31T00` and `2025-07-31T03` from the OVN POD `ovnkube-node-abcde`

  ```bash
  ./check_assigned_ips.sh -p ovnkube-node-abcde -s 2025-07-31T00 -e 2025-07-31T03
  ```

- Display the OVN information POD created between the `2025-07-31T00` and `2025-07-31T03` from the node `worker0`, and sorting the output based on `podIP`

  ```bash
  ./check_assigned_ips.sh -n worker0 -s 2025-07-31T00 -e 2025-07-31T03 -S podIP
  ```

- Display the OVN information POD created between the `2025-07-31T00` and `2025-07-31T03` from the node `worker0` in a json format.

  ```bash
  ./check_assigned_ips.sh -n worker0 -s 2025-07-31T00 -e 2025-07-31T03 -o json
  ```
