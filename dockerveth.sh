#!/bin/bash

# 
containers=$(docker ps --format "{{.ID}} {{.Names}}")

# 
host_veths=$(ip -json link show type veth | jq -r '.[] | [.ifindex, .ifname] | join(" ")')

printf "%-15s %-20s %-10s\n" "CONTAINER ID" "NAME" "VETH"

while read -r id name; do
    # 
    pid=$(docker inspect --format '{{.State.Pid}}' "$id")

    # 
    link_index=$(nsenter -t "$pid" -n ip -json link show type veth | jq '.[0].link_index // empty')

    # 
    veth_name="N/A"
    while read -r ifindex ifname; do
        if [[ "$ifindex" == "$link_index" ]]; then
            veth_name="$ifname"
            break
        fi
    done <<< "$host_veths"

    # 
    printf "%-15s %-20s %-10s\n" "$id" "$name" "$veth_name"
done <<< "$containers"