#!/bin/bash
##################################################################
# Script       # check_assigned_ips.sh
# Description  # List the PODs' IPs claim and release from the ovn-controller logs for a specific timeframe
##################################################################
# @VERSION     # 0.1.0
##################################################################
# Changelog.md # List the modifications in the script.
# README.md    # Describes the repository usage
##################################################################

##### Functions
# Help
fct_help(){
  Script=$(which $0 2>${STD_ERR})
  if [[ "${Script}" != "bash" ]] && [[ ! -z ${Script} ]]
  then
    ScriptName=$(basename $0)
  fi
  echo -e "usage: ${cyantext}${ScriptName} -n <nodename>|-p <pod_name> -s <YYYY-mm-ddTHH> -e <YYYY-mm-ddTHH> [-o csv|json] [-S startTime|podName|podIP|podMac|stopTime] ${purpletext}[-h]${resetcolor}\n"
  OPTION_TAB=8
  DESCR_TAB=80
  DETAILS_TAB=10
  printf "|%${OPTION_TAB}s---%-${DESCR_TAB}s---%-${DETAILS_TAB}s|\n" |tr \  '-'
  printf "|%${OPTION_TAB}s | %-${DESCR_TAB}s | %-${DETAILS_TAB}s|\n" "Options" "Description" "[Details]"
  printf "|%${OPTION_TAB}s | %-${DESCR_TAB}s | %-${DETAILS_TAB}s|\n" |tr \  '-'
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | %-${DESCR_TAB}s | ${greentext}%-${DETAILS_TAB}s${resetcolor}|\n" "-n" "set the related nodename to find the related POD" ""
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | %-${DESCR_TAB}s | ${greentext}%-${DETAILS_TAB}s${resetcolor}|\n" "-p" "use a PODNAME instead of the nodename" ""
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | %-${DESCR_TAB}s | ${greentext}%-${DETAILS_TAB}s${resetcolor}|\n" "-s" "defined the start of the timeframe (UTC) in a format 'YYYY-mm-ddTHH'" ""
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | %-${DESCR_TAB}s | ${greentext}%-${DETAILS_TAB}s${resetcolor}|\n" "-e" "defined the end of the timeframe (UTC)in a format 'YYYY-mm-ddTHH' (not included)" ""
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | %-${DESCR_TAB}s | ${greentext}%-${DETAILS_TAB}s${resetcolor}|\n" "-o" "provide the output in a 'csv' or 'json' format" ""
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | %-${DESCR_TAB}s | ${greentext}%-${DETAILS_TAB}s${resetcolor}|\n" "-S" "Sort by 'startTime', 'podName', 'podIP', 'podMac', 'stopTime'" "startTime"
  printf "|%${OPTION_TAB}s-|-%-${DESCR_TAB}s-|-%-${DETAILS_TAB}s|\n" |tr \  '-'
  printf "|%${OPTION_TAB}s | %-${DESCR_TAB}s | %-${DETAILS_TAB}s|\n" "" "Examples:" ""
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | ${yellowtext}%-${DESCR_TAB}s${resetcolor} | ${greentext}%-${DETAILS_TAB}s${resetcolor}|\n" "" " - for a timeframe starting on 2025 August 9th at 10 am: '-s 2025-08-09T10'" ""
  printf "|${cyantext}%${OPTION_TAB}s${resetcolor} | ${yellowtext}%-${DESCR_TAB}s${resetcolor} | ${greentext}%-${DETAILS_TAB}s${resetcolor}|\n" "" " - for a timeframe ending on 2025 August 9th at 01 pm: '-e 2025-08-09T13'" ""
  printf "|%${OPTION_TAB}s-|-%-${DESCR_TAB}s-|-%-${DETAILS_TAB}s|\n" |tr \  '-'
  printf "|%${OPTION_TAB}s | %-${DESCR_TAB}s | %-${DETAILS_TAB}s|\n" "" "Additional Options:" ""
  printf "|%${OPTION_TAB}s-|-%-${DESCR_TAB}s-|-%-${DETAILS_TAB}s|\n" |tr \  '-'
  printf "|${purpletext}%${OPTION_TAB}s${resetcolor} | %-${DESCR_TAB}s | %-${DETAILS_TAB}s|\n" "-h" "display this help and check for updated version" ""
  printf "|%${OPTION_TAB}s---%-${DESCR_TAB}s---%-${DETAILS_TAB}s|\n" |tr \  '-'

  Script=$(which $0 2>${STD_ERR})
  if [[ "${Script}" != "bash" ]] && [[ ! -z ${Script} ]]
  then
    VERSION=$(grep "@VERSION" ${Script} 2>${STD_ERR} | grep -Ev "VERSION=" | cut -d'#' -f3)
    VERSION=${VERSION:-" N/A"}
  fi
  echo -e "\nCurrent Version:\t${VERSION}"
}

##### Main

##### Default/Main Variables
# Default variables
ScriptName="mg_cluster_status.sh"
DEFAULT_OC="omc"
DEFAULT_TRUNK="100"
DEFAULT_WIDE="true"
DEFAULT_CONDITION_TRUNK="220"
DEFAULT_MIN_RESTART="10"
DEFAULT_TAIL_LOG="15"
DEFAULT_NODE_TRANSITION_DAYS=2
DEFAULT_OPERATOR_TRANSITION_DAYS=2
DEFAULT_graytext="\x1B[30m"
DEFAULT_redtext="\x1B[31m"
DEFAULT_greentext="\x1B[32m"
DEFAULT_yellowtext="\x1B[33m"
DEFAULT_bluetext="\x1B[34m"
DEFAULT_purpletext="\x1B[35m"
DEFAULT_cyantext="\x1B[36m"
DEFAULT_whitetext="\x1B[37m"
DEFAULT_resetcolor="\x1B[0m"
# Defining a Variable to exclude all of the undesired messages from omc, oc, ...
MESSAGE_EXCLUSION="^$|^No resources|^resource type|^Error from server (NotFound):"
# version time_gap
Time_Gap_Alert=${Time_Gap_Alert:-7776000}         # => 90 days gap
# Color list
graytext=${graytext:-${DEFAULT_graytext}}
redtext=${redtext:-${DEFAULT_redtext}}
greentext=${greentext:-${DEFAULT_greentext}}
yellowtext=${yellowtext:-${DEFAULT_yellowtext}}
bluetext=${bluetext:-${DEFAULT_bluetext}}
purpletext=${purpletext:-${DEFAULT_purpletext}}
cyantext=${cyantext:-${DEFAULT_cyantext}}
whitetext=${whitetext:-${DEFAULT_whitetext}}
resetcolor=${resetcolor:-${DEFAULT_resetcolor}}
# Max random number to check for update
MAX_RANDOM=10
# Set a default STD_ERR, which can be replaced for debugging to "/dev/stderr"
STD_ERR="${STD_ERR:-/dev/null}"
# Number of exclusive options
NB_OPT=0
# OC command
OC=${OC:-${DEFAULT_OC}}

# Getops
if [[ $# != 0 ]]
then
  INSIGHTS_OPTIONS=""
  if [[ $1 == "-" ]] || [[ $1 =~ ^[a-zA-Z0-9] ]]
  then
    echo -e "Invalid option: ${1}\n"
    fct_help && exit 1
  fi
  while getopts :hn:o:p:s:e:S: arg; do
  case $arg in
      n)
        NODENAME=${OPTARG}
        NB_OPT=$[NB_OPT + 1]
        ;;
      p)
        OVNPOD=${OPTARG}
        NB_OPT=$[NB_OPT + 1]
        ;;
      o)
        if [[ ${OPTARG} == "json" ]] || [[ ${OPTARG} == "csv" ]]
        then
          OUTPUT=${OPTARG}
        else
          echo -e "Invalid option: '-o ${OPTARG}'\n"
          fct_help && exit 2
        fi
        ;;
      s)
        STARTTIME=${OPTARG}
        ;;
      e)
        ENDTIME=${OPTARG}
        ;;
      S)
          case ${OPTARG} in
            "podName")
              DISPLAY="NAME"
              ;;
            "podIP")
              DISPLAY="IP"
              ;;
            "podMac")
              DISPLAY="MAC"
              ;;
            "stopTime")
              DISPLAY="STOP"
              ;;
            ?)
              DISPLAY="START"
              ;;
          esac
        ;;
      h)
        fct_help && exit 0
        ;;
      ?)
        echo -e "Invalid option\n"
        fct_help && exit 1
        ;;
  esac
  done
fi
DISPLAY=${DISPLAY:-"START"}

# Variables validation
if [[ ${NB_OPT} != 1 ]]
then
  echo "Err: Invalid arguments, you should specify only ONE '-n' or '-p' option"
  fct_help && exit 3
fi
if [[ -z ${ENDTIME} ]] || [[ -z ${STARTTIME} ]]
then
  echo "Err: Both '-s <YYYY-mm-ddTHH>' and '-e <YYYY-mm-ddTHH>' are required!"
  fct_help && exit 4
fi
if [[ ! -z ${NODENAME} ]]
then
  OVNPOD=$(${OC} get pod -n openshift-ovn-kubernetes -l app=ovnkube-node -o json 2>${STD_ERR} | grep -Ev "${MESSAGE_EXCLUSION}" | jq -r --arg node ${NODENAME} '.items[] | select(.spec.nodeName == $node) | .metadata.name')
  if [[ -z ${OVNPOD} ]]
  then
    echo "Err: Unable to retrieve the OVN POD for the node ${NODENAME}"
    fct_help && exit 5
  fi
else
  if [[ -z ${OVNPOD} ]]
  then
    echo "Err: OVN POD not found or not spoecified"
    fct_help && exit 6
  else
    NODENAME=$(${OC} get pod -n openshift-ovn-kubernetes ${OVNPOD} -o json 2>${STD_ERR} | grep -Ev "${MESSAGE_EXCLUSION}" | jq -r '.spec.nodeName')
    if [[ -z ${NODENAME} ]]
    then
      echo "Err: Unable to find the ovn POD: ${OVNPOD}"
      fct_help && exit 7
    fi
  fi
fi

# Extracting the data from the ovn-controller POD log.
EXTRACTED_DATA=$(${OC} logs -n openshift-ovn-kubernetes ${OVNPOD} -c ovn-controller 2>${STD_ERR} | grep -Ev "${MESSAGE_EXCLUSION}" | awk "/${STARTTIME}[.:0-9]{10}Z/,/${ENDTIME}[.:0-9]{10}Z/" | sed -e '$d')

if [[ -z ${EXTRACTED_DATA} ]]
then
  echo -e "Unable to retrieve the desired timeframe from the OVN POD ${cyantext}${OVNPOD}s${resetcolor} for the node ${cyantext}${NODENAME}s${resetcolor}.\nPlease review the timeframe rang."
  fct_help && exit 10
fi

# Creating the JSON array from the extracted data.
ITEMS_ARRAY='{ "items": [] }'
for PODDATA in $(echo "${EXTRACTED_DATA}" |  grep "up in Southbound$" | awk -F'|' '{split($1,a," ");split($NF,b," ");if(a[2] != ""){print a[2]"|"b[3]}else{print a[1]"|"b[3]}}')
do
  PODNAME=$(echo ${PODDATA} | cut -d'|' -f2)
  PODSTART=$(echo ${PODDATA} | cut -d'|' -f1)
  PODDATA=$(echo "${EXTRACTED_DATA}" | grep "${PODNAME}: Claiming")
  PODIP=$(echo ${PODDATA} | awk '{print $NF}')
  PODMAC=$(echo ${PODDATA} | awk '{print $(NF-1)}')
  PODSTOP=$(echo "${EXTRACTED_DATA}" | grep " ${PODNAME} down in Southbound" | awk -F'|' '{split($1,a," ");if(a[2] != ""){print a[2]}else{print a[1]}}')
  JQ_ARG="{\"podName\":\"${PODNAME}\",\"startTime\":\"${PODSTART}\",\"stopTime\":\"${PODSTOP:-null}\",\"podIP\":\"${PODIP:-null}\",\"podMacAddress\":\"${PODMAC:-null}\"}"
  ITEMS_ARRAY=$(echo ${ITEMS_ARRAY} | jq --argjson p "${JQ_ARG}" '.items += [$p]')
done

# Displaying the result
if [[ -z ${OUTPUT} ]]
then
  echo -e "\n########################################\n# Data extraction from the OVN POD ${cyantext}${OVNPOD}s${resetcolor} for the node ${cyantext}${NODENAME}s${resetcolor}.\n########################################"
  case ${DISPLAY} in
    IP)
        echo ${ITEMS_ARRAY} | jq -r '"| PODNAME,| PODIP,| PODMACADDRESS,| STARTTIME,| STOPTIME,|",(.items | sort_by(.podIP) | .[] | "| \(.podName),| \(.podIP),| \(.podMacAddress),| \(.startTime),| \(.stopTime),|")' | column -ts','
        ;;
    MAC)
        echo ${ITEMS_ARRAY} | jq -r '"| PODNAME,| PODIP,| PODMACADDRESS,| STARTTIME,| STOPTIME,|",(.items | sort_by(.podMacAddress) | .[] | "| \(.podName),| \(.podIP),| \(.podMacAddress),| \(.startTime),| \(.stopTime),|")' | column -ts','
        ;;
    NAME)
        echo ${ITEMS_ARRAY} | jq -r '"| PODNAME,| PODIP,| PODMACADDRESS,| STARTTIME,| STOPTIME,|",(.items | sort_by(.podName) | .[] | "| \(.podName),| \(.podIP),| \(.podMacAddress),| \(.startTime),| \(.stopTime),|")' | column -ts','
        ;;
    START)
        echo ${ITEMS_ARRAY} | jq -r '"| PODNAME,| PODIP,| PODMACADDRESS,| STARTTIME,| STOPTIME,|",(.items | sort_by(.startTime) | .[] | "| \(.podName),| \(.podIP),| \(.podMacAddress),| \(.startTime),| \(.stopTime),|")' | column -ts','
        ;;
    STOP)
        echo ${ITEMS_ARRAY} | jq -r '"| PODNAME,| PODIP,| PODMACADDRESS,| STARTTIME,| STOPTIME,|",(.items | sort_by(.stopTime) | .[] | "| \(.podName),| \(.podIP),| \(.podMacAddress),| \(.startTime),| \(.stopTime),|")' | column -ts','
        ;;
  esac
else
  case ${OUTPUT} in
    csv)
        echo ${ITEMS_ARRAY} | jq -r '"PODNAME,PODIP,PODMACADDRESS,STARTTIME,STOPTIME",(.items[] | "\(.podName),\(.podIP),\(.podMacAddress),\(.startTime),\(.stopTime)")'
        ;;
    json)
        echo "${ITEMS_ARRAY}"
        ;;
  esac
fi
