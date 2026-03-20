#!/bin/bash

systemd-run --user kitty -e bash -ic "$*"
