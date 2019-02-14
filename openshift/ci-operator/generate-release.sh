#!/bin/bash

branch=${1-'knative-v0.3'}
target=${2-'origin-v4.0'}

cat <<EOF
tag_specification:
  cluster: https://api.ci.openshift.org
  name: $target
  namespace: openshift
base_images:
  base:
    cluster: https://api.ci.openshift.org
    name: $target
    namespace: openshift
    tag: base
build_root:
  project_image:
    dockerfile_path: openshift/ci-operator/build-image/Dockerfile
canonical_go_repository: github.com/knative/serving
binary_build_commands: make install
test_binary_build_commands: make test-install
promotion:
  cluster: https://api.ci.openshift.org
  namespace: openshift
  name: $branch
tests:
- as: e2e
  commands: "make test-e2e"
  openshift_installer_src:
    cluster_profile: aws
resources:
  '*':
    limits:
      memory: 4Gi
    requests:
      cpu: 100m
      memory: 200Mi
images:
EOF

core_images=$(find ./openshift/ci-operator/knative-images -mindepth 1 -maxdepth 1 -type d)
for img in $core_images; do
  image_base=$(basename $img)
  cat <<EOF
- dockerfile_path: openshift/ci-operator/knative-images/$image_base/Dockerfile
  from: base
  inputs:
    bin:
      paths:
      - destination_dir: .
        source_path: /go/bin/$image_base
  to: knative-serving-$image_base
EOF
done

test_images=$(find ./openshift/ci-operator/knative-test-images -mindepth 1 -maxdepth 1 -type d)
for img in $test_images; do
  image_base=$(basename $img)
  cat <<EOF
- dockerfile_path: openshift/ci-operator/knative-test-images/$image_base/Dockerfile
  from: base
  inputs:
    test-bin:
      paths:
      - destination_dir: .
        source_path: /go/bin/$image_base
  to: knative-serving-test-$image_base
EOF
done