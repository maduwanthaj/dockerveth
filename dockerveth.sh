#!/bin/bash

# initialize an array to store table rows
table_rows=()

# log errors and exit
log_error() {
    echo "Error: ${1}" >&2
    exit 1
}

# ensure the script is run as root or with sudo privileges
if [ "$EUID" -ne 0 ]; then
    log_error "this script requires root privileges. please run it as root or use sudo."
fi

# check if required commands are installed
for cmd in docker ip nsenter jq; do
    command -v "${cmd}" > /dev/null 2>&1 || log_error "the required command '${cmd}' is not installed. please install it and try again."
done

# fetch the list of running containers
if [[ $(docker ps --quiet | wc -l) -gt 0 ]]; then
    containers=$(docker ps --format "{{.ID}} {{.Names}}") || log_error "unable to fetch the list of running containers."
else
    log_error "no running Docker containers found."
fi

# fetch all veth interface details on the host
host_veths=$(ip -json link show type veth | jq -r '.[] | [.ifindex, .ifname] | join(" ")')

# process each container to fetch its associated veth interface 
while read -r id name; do
    # fetch the container's PID
    pid=$(docker inspect --format '{{.State.Pid}}' "${id}") || log_error "Could not fetch PID for container ID: ${id} NAME: ${name}."

    # fetch the link index for the container's veth interface
    link_index=$(nsenter -t "${pid}" -n ip -json link show type veth | jq '.[0].link_index // empty') \
    || log_error "Could not fetch link index for container ID: ${id} NAME: ${name}."

    # match the link index with the host veth interface
    veth_name="--"
    while read -r ifindex ifname; do
        if [[ "$ifindex" == "$link_index" ]]; then
            veth_name="${ifname}"
            break
        fi
    done <<< "$host_veths"

    # append the row to the table
    table_rows+=("${id} ${name} ${veth_name}")  
    
done <<< "$containers"

# determine name column width dynamically
max_name_width=$(printf "%s\n" "${table_rows[@]}" | awk '{print length($2)}' | sort -nr | head -1)

# adjust width for short and long names
max_name_width=$((max_name_width > 4 ? max_name_width : 4))

# print the header
printf "%-12s  %-${max_name_width}s  %-11s\n" "CONTAINER ID" "NAME" "VETH"

# print the table rows
for row in "${table_rows[@]}"; do
    printf "%-12s  %-${max_name_width}s  %-11s\n" $(echo "$row")
done