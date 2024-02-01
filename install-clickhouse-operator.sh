set -e
echo "$1" > /tmp/kubeconfig
KUBECONFIG=/tmp/kubeconfig
MANIFEST="$2"

# Check if resources are already applied
if kubectl get -f $MANIFEST --kubeconfig $KUBECONFIG; then
  echo "Manifest already applied, checking for differences..."

  # Diff the current and new manifests
  if kubectl diff -f $MANIFEST --kubeconfig $KUBECONFIG; then
    echo "No changes detected."
    exit 0
  else
    if [ $3 = "false" ]; then
      echo "There are differences between the current and new manifests."
      echo "If you want to confirm these changes you have to run \`terraform apply -var=\"confirm_operator_manifest_changes=true\"\`"
      exit 1
    else
      echo "var.confirm_operator_manifest_changes is set to true, applying changes..."
    fi
  fi
fi

# Apply the manifest
kubectl apply -f $MANIFEST --kubeconfig $KUBECONFIG
rm /tmp/kubeconfig # Clean up
