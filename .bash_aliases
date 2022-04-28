#! /usr/bin/env bash

build (){
	if catkin build "$@"
	then
		echo 🍻
	else
		echo 💔
	fi
}
build_only(){
	build "$@" --no-deps
}

# source
alias s='source $HOME/.bashrc'
alias z='source $HOME/.zshrc'

# ros
alias cb='build'
alias cbn='build_only'
alias ros="roscd && cd ../src"
alias cross='cd $HOME/workspace/catkin/cross'

# git
alias rb="git rebase -i origin/master"

# dev
alias todo='micro $HOME/workspace/todo.txt'
alias dbash="docker exec -it scout-dev bash"
alias dzsh="docker exec -it scout-dev zsh"
alias u='$HOME/workspace/unreal_linux_build/ScoutAirSim.sh'
alias unreal="/home/ola/workspace/UnrealEngine/Engine/Binaries/Linux/UE4Editor"
alias work="cd ~/workspace"
alias sim="roslaunch scout_simulation full.launch"
alias simu="roslaunch scout_simulation full.launch simulator:=airsim"
