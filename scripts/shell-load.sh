#!/bin/bash

cd $HOME/.dotfiles/ > /dev/null 2>&1
git fetch > /dev/null 2>&1
git status
cd $HOME > /dev/null 2>&1
