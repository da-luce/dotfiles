#!/bin/bash

cd $HOME/.dotfiles/ > /dev/null 2>&1
git fetch > /dev/null 2>&1
git status
git submodule update --remote --merge
cd $HOME > /dev/null 2>&1
