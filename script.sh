echo "Waiting for 1 Kubernetes nodes to be Ready..."
while true; do
    kubectl wait --for=condition=Ready nodes --all --timeout=600s
    if [ $? -eq 0 ]; then
        echo "All nodes ready"
        exit 0
    fi

    echo "Nodes no ready yet, waiting 30 seconds to try again..."
    sleep 30
done
# for i in {1..40}; do
#     kubectl wait --for=condition=Ready nodes --all --timeout=600s || true
# done
# echo "Timeout waiting for ${var.expected_node_count} nodes to become Ready."


# ready=$(kubectl get nodes --no-headers 2>/dev/null | grep -c " Ready ")
# if [ "$ready" -eq "1" ]; then
#     echo "All $ready nodes are Ready."
#     exit 0
# fi
# echo "Currently Ready: $ready / ${var.expected_node_count} — retrying ($i)..."
# sleep 30
# done
# exit 1