#!/bin/bash

docker rm $(docker ps -a | grep '\sExited' | grep genome-strip)
