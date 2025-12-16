#!/bin/bash

yay -Qqe > ~/pkglist.txt
chezmoi add ~/pkglist.txt
