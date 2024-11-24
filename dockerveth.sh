#!/bin/bash

# log errors and exit
log_error() {
    echo "Error: ${1}" >&2
    exit 1
}

# ensure the script is run as root or with sudo privileges
if [[ "$EUID" -ne 0 ]]; then
    log_error "this script requires root privileges. please run it as root or use sudo."
fi

# check if required commands are installed
for cmd in docker ip nsenter jq; do
    command -v "${cmd}" > /dev/null 2>&1 || \
    log_error "the required command '${cmd}' is not installed. please install it and try again."
done

# fetch the list of running containers
if [[ $(docker ps --quiet | wc -l) -gt 0 ]]; then
    containers=$(docker ps --format "{{.ID}} {{.Names}}") \
    || log_error "unable to fetch the list of running containers."
else
    log_error "no running Docker containers found."
fi

# fetch all veth interface details on the host and store in an associative array
declare -A host_veth_map
while read -r ifindex ifname; do
    host_veth_map["$ifindex"]="$ifname"
done < <(ip -json link show type veth | jq -r '.[] | [.ifindex, .ifname] | join(" ")')

# initialize arrays to store table data
declare -a container_ids container_names container_veths

# process each container 
while read -r container_id container_name; do
    # fetch container's PID
    pid=$(docker inspect --format '{{.State.Pid}}' "${container_id}") \
    || log_error "Could not fetch PID for container ID: ${container_id} NAME: ${container_name}."

    # fetch the link index for the container's veth interface
    link_index=$(nsenter -t "${pid}" -n ip -json link show type veth | jq '.[0].link_index // 0') \
    || log_error "Could not fetch link index for container ID: ${container_id} NAME: ${container_name}."

    # find the veth name using the link index
    veth_name="${host_veth_map[$link_index]:---}"

    # store data in arrays
    container_ids+=("$container_id")
    container_names+=("$container_name")
    container_veths+=("$veth_name")
done <<< "$containers"

# adjust column width for short and long names
max_name_width=4 # minimum width for "NAME"

for name in "${container_names[@]}"; do
    name_len=${#name}
    (( name_len > max_name_width )) && max_name_width=$name_len
done

# print the header
printf "%-12s  %-${max_name_width}s  %-11s\n" "CONTAINER ID" "NAME" "VETH"

# print the rows
for i in "${!container_ids[@]}"; do
    printf "%-12s  %-${max_name_width}s  %-11s\n" "${container_ids[i]}" "${container_names[i]}" "${container_veths[i]}"
done