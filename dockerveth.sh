#!/bin/bash

# 
log_error() {
    echo "Error: ${1}" >&2
    exit 1
}

#
if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run as root or with sudo privileges."
fi

# 
for cmd in docker ip nsenter jq; do
    command -v "${cmd}" > /dev/null 2>&1 || log_error "${cmd} is not installed."
done

# 
containers=$(docker ps --format "{{.ID}} {{.Names}}") || log_error "Failed to fetch container list."

# 
host_veths=$(ip -json link show type veth | jq -r '.[] | [.ifindex, .ifname] | join(" ")')

printf "%-15s %-20s %-10s\n" "CONTAINER ID" "NAME" "VETH"

while read -r id name; do
    # 
    pid=$(docker inspect --format '{{.State.Pid}}' "${id}") || log_error "Could not fetch PID for container ID: ${id} NAME: ${name}."

    # 
    link_index=$(nsenter -t "${pid}" -n ip -json link show type veth | jq '.[0].link_index // empty') \
    || log_error "Could not fetch link index for container ID: ${id} NAME: ${name}."

    # 
    veth_name="N/A"
    while read -r ifindex ifname; do
        if [[ "$ifindex" == "$link_index" ]]; then
            veth_name="${ifname}"
            break
        fi
    done <<< "$host_veths"

    # 
    printf "%-15s %-20s %-10s\n" "${id}" "${name}" "${veth_name}"
done <<< "$containers"