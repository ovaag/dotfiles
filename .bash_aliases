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

copy_to_drone(){
	scp "$1" root@"$(scout-find-drone)":"$2"
}

cleanup() {
    echo "Killing roscore"
    kill "$ROSCORE_PID"
    kill "$PCL_ROS_PID"
}


cloud_rviz(){
    if [ ! -f "$1" ]; then
       echo "Input file does not exist: $1"
       return 1
    fi
	if ! pgrep -x "rosmaster" > /dev/null; then 
		    echo "Starting roscore"
		    roscore &
		    ROSCORE_PID=$!
		    
		    # Set trap to call cleanup function on script exit
		    trap cleanup EXIT
	fi
	rosrun pcl_ros pcd_to_pointcloud "$1" 1.0 _latch:=true _frame_id:=map &
	PCL_ROS_PID=$!
	rviz -d ~/workspace/rviz_configs/pcd_viewer.rviz
}

metrical() {
    docker run --rm --init --user="$(id -u):$(id -g)" \
    --volume="/home/ola/bags/internal/calibration":"/datasets" \
    --workdir="/datasets" \
    --add-host=host.docker.internal:host-gateway \
    --volume=/home/ola/.config/tangram-vision/config.toml:/.config/tangram-vision/config.toml:ro \
    tangramvision/cli:dev-latest \
    "$@";
    }

gocker() {
	tmp_docker=$(sudo find /tmp -type d  -name '.docker*')
	docker run --rm -it --name gui-docker --network host --gpus all \
	--privileged -e SSH_AUTH_SOCK -v /run/user/1000/keyring/ssh:/run/user/1000/keyring/ssh \
	-e DISPLAY -e TERM -e QT_X11_NO_MITSHM=1 -e XAUTHORITY="$tmp_docker" \
	-v "$tmp_docker":"$tmp_docker" -v /tmp/.X11-unix:/tmp/.X11-unix \
	-v /etc/localtime:/etc/localtime:ro \
	"$@"
}

ola-qgc() {
	docker run -it --privileged --gpus=all --runtime=nvidia --network host \
	 --volume /home/ola/workspace/:/home/ola/workspace \
	 qgc-launch \
	 /home/ola/workspace/qgroundcontrol/build/staging/CustomQGroundControl
}

ola-qgc-build-appimage() {
	docker run --rm --device /dev/fuse --privileged \
	-v "$HOME"/workspace/qgroundcontrol:/project/source \
	-v "$HOME"/workspace/qgroundcontrol/build:/project/build \
	qgc-build-appimage:latest
}

ola-qgc-build-apk() {
	docker run --rm --device /dev/fuse --privileged \
	-v "$HOME"/workspace/qgroundcontrol:/project/source \
	-v "$HOME"/workspace/qgroundcontrol/android_build:/project/android_build \
	qgc-build-apk
}

function ola-set-ws {
    local new_ws=$1
    if [[ -z "$new_ws" ]]; then
        echo "Please provide a workspace name."
        return 1
    fi

    local file="$HOME/.scout-zshrc"
    local new_line="source $HOME/workspace/catkin/$new_ws/devel/setup.zsh"

    # Ensure the target file exists
    if [[ ! -f "$file" ]]; then
        echo "The file $file does not exist."
        return 1
    fi

    # Change the workspace source line
    sed -i "s|source $HOME/workspace/catkin/.*|${new_line}|" "$file"

    echo "Workspace set to '$new_ws'."
}

#drone
alias scpd='copy_to_drone'

# source
alias s='source $HOME/.bashrc'
alias z='source $HOME/.zshrc'

# ros
alias cb='build'
alias cbn='build_only'
alias ros="roscd && cd ../src"
alias cross='cd $HOME/workspace/catkin/cross && source scout-source-crosscompile -s ~/workspace/sdks/cpr-gtsam'

# git
alias rb="git rebase -i origin/master"
alias gca="git add . && git commit --amend --no-edit"

# dev
alias todo='micro $HOME/workspace/todo.txt'
alias dbash="docker exec -it scout-dev-noetic bash"
alias dzsh="docker exec -it scout-dev-noetic zsh"
alias u='$HOME/workspace/unreal_linux_build/ScoutAirSim.sh'
alias unreal="/home/ola/workspace/UnrealEngine/Engine/Binaries/Linux/UE4Editor"
alias work="cd ~/workspace"
alias sim="roslaunch scout_simulation full.launch"
alias simu="roslaunch scout_simulation full.launch simulator:=airsim"
alias t="trash-put"
alias c="clear"
alias ola-plotjuggler="(source /home/ola/Code/plotjuggler_ws/devel/setup.zsh && roslaunch plotjuggler_ros plotjuggler.launch)"
alias cloud_viz='cloud_rviz'

scout-clone() {
	git clone git@github.com:scoutdi/"$@".git
}
