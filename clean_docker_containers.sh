#!/bin/bash

docker rm $(docker ps -a | grep 'Exited' | grep strip | awk '{print $1}')
