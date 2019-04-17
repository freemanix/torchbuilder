#!/bin/bash

VERSION=1.0.1

docker run --rm torchbuilder tar czf - libtorch >libtorch-${VERSION}.tgz
