#!/bin/bash

USAGE="$(basename "$0") [-c] [-n <NETWORK_NAME>] -- Docker Swarm 네트워크 사용량 확인

Options:
    -c                컨테이너 정보 포함
    -n <NETWORK_NAME> 특정 네트워크 정보만 검색"

RED="\033[01;31m"
YELLOW="\033[01;33m"
GREEN="\033[01;32m"
NC="\033[00m"

CONTAINER=0

while getopts "hcn:" opt; do
    case "${opt}" in
        c)
            CONTAINER=1
            ;;
        n)
            NETWORKS=$OPTARG
            ;;
        h)
            echo "$USAGE"
            exit
            ;;
        *)
            echo "$USAGE"
            exit
            ;;
    esac
done

if [ -z "$NETWORKS" ]; then
    echo -e "${RED}네트워크 목록 읽는 중...${NC}" | tr -d '\n'
    NETWORKS=$(docker network ls --filter 'scope=swarm' -q)
    echo -e "\r" | tr -d '\n'
fi

for NETWORK in $NETWORKS; do
    SERVICE_COUNT=0
    CONTAINER_COUNT=0
    TOTAL_COUNT=0
    OUTPUT=""
    echo -e "${RED}네트워크 정보 읽는 중...${NC} (${NETWORK})" | tr -d '\n'
    NET_INFO=$(docker network inspect -v $NETWORK)
    echo -e "\r" | tr -d '\n'
    NET_NAME=$(jq -r '.[].Name' <<< $NET_INFO)
    NET_ID=$(jq -r '.[].Id' <<< $NET_INFO)
    NET_ATTACHABLE=$(jq -r '.[].Attachable' <<< $NET_INFO)
    NET_SUBNET=$(jq -r '.[].IPAM.Config[].Subnet' <<< $NET_INFO)
    SERVICES=$(jq -r '.[].Services | keys[]' <<< $NET_INFO)
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    echo -e "${GREEN}Name${NC}       : $NET_NAME"
    echo -e "${GREEN}ID${NC}         : $NET_ID"
    echo -e "${GREEN}Subnet${NC}     : $NET_SUBNET"
    echo -e "${GREEN}Attachable${NC} : $NET_ATTACHABLE"
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    SERVICE_COUNT=$(echo "$SERVICES" | wc -l)
    for SERVICE in $SERVICES; do
        i=$((i%4 + 1))
        echo -e "\r${RED}서비스 정보 읽는 중...${NC} " | tr -d '\n'
        echo -e '|/-\' | cut -b $i | tr -d '\n'
        SERVICE_INFO=$(jq -r '.[].Services["'$SERVICE'"]'  <<< $NET_INFO)
        SERVICE_VIP=$(jq -r '.VIP' <<< $SERVICE_INFO)
        if [ ${CONTAINER} -eq 1 ]; then
            TASKS=$(jq -r '.Tasks[] | "└─|\(.Name)|\(.EndpointIP)"' <<< $SERVICE_INFO)
            TASK_COUNT=$(echo "$TASKS" | wc -l)
            OUTPUT="${OUTPUT}*─|${SERVICE}|${SERVICE_VIP}|${TASK_COUNT}\n"
        else
            TASK_COUNT=$(jq -r '.Tasks[] | .Name' <<< $SERVICE_INFO | wc -l)
            OUTPUT="${OUTPUT}${SERVICE}|${SERVICE_VIP}|${TASK_COUNT}\n"
        fi
        CONTAINER_COUNT=$(expr $CONTAINER_COUNT + $TASK_COUNT)
        if [ ${CONTAINER} -eq 1 ]; then
            OUTPUT="${OUTPUT}${TASKS}\n"
        fi
    done
    printf '\r'
    echo -e "${OUTPUT}" | column -t -s '|'
    TOTAL_COUNT=$(expr $SERVICE_COUNT + $CONTAINER_COUNT)
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    echo -e "${GREEN}VIP${NC}        : $SERVICE_COUNT"
    echo -e "${GREEN}Containers${NC} : $CONTAINER_COUNT"
    echo -e "${GREEN}Total${NC}      : $TOTAL_COUNT"
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
done
