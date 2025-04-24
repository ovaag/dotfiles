#! /usr/bin/env bash

checklist() {
    cat <<EOF

* [x] If relevant: Power cycle the drone at least once when testing (instead of just restarting services)
* Does this make changes to the camera manager?
  * [ ] Yes, and I have power cycled the drone 3 times and seen no startup issues/startup artifacts/similar
  * [ ] No significant changes
* [x] Cross-compilation succeeds on the default SDK
* Update node descriptions (comment at the top of each node's source file):
  * [ ] Done
  * [x] Not needed
* Update package descriptions (\`<description>\` tag in package.xml):
  * [ ] Done
  * [x] Not needed
* Update the [software release test](https://github.com/scoutdi/software-release-test/blob/master/.github/ISSUE_TEMPLATE):
  * [ ] Done
  * [x] Not needed
* Add to the [changelog](https://github.com/orgs/scoutdi/projects/186/views/1) if [needed](https://github.com/orgs/scoutdi/projects/186/views/1?pane=info)
  * [ ] Done
    * [ ] If the change is significant: Notify [#operations](https://scoutdi.slack.com/archives/C05S5V1QSHW) about the update
  * [x] Not needed
* Request a [user manual](https://github.com/scoutdi/user-manual) update by opening an issue
  * [ ] Done
  * [x] Not needed
* Does this change topic names or message definitions in a non-backwards compatible way?
  * [ ] Yes, and I've incremented the rosbag version [in this file](https://github.com/scoutdi/scout_ros/blob/master/scout_streamer/scripts/scout_version_logger.py) and added topic renames [here](https://github.com/scoutdi/scout_ros/blob/master/scout_replay/src/scout_replay/migrations.py)
  * [x] No

EOF
}

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

# gocker() {
	# tmp_docker=$(sudo find /tmp -type d  -name '.docker*')
	# docker run --rm -it --name gui-docker --network host --gpus all \
	# --privileged -e SSH_AUTH_SOCK -v /run/user/1000/keyring/ssh:/run/user/1000/keyring/ssh \
	# -e DISPLAY -e TERM -e QT_X11_NO_MITSHM=1 -e XAUTHORITY="$tmp_docker" \
	# -v "$tmp_docker":"$tmp_docker" -v /tmp/.X11-unix:/tmp/.X11-unix \
	# -v /etc/localtime:/etc/localtime:ro \
	# "$@"
# }

# Run a container with gui access on a nvidia gpu computer
gocker() {
    # Allow local root access to X server
    xhost +local:root > /dev/null 2>&1

    # Run the container with GUI support and any additional arguments
    docker run -it --rm \
        --gpus all \
        --runtime=nvidia \
        -e DISPLAY=$DISPLAY \
        -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
        --device /dev/dri \
        --device /dev/nvidia0 \
        --device /dev/nvidiactl \
        --device /dev/nvidia-uvm \
        --privileged \
        "$@"

    # Revoke X server access after container exit for security
    xhost -local:root > /dev/null 2>&1
}
        # --network=host \

gz_bridge(){
	docker exec humble-gz /ros_entrypoint.sh ros2 run ros_gz_bridge parameter_bridge \
	        "/world/default/dynamic_pose/info@geometry_msgs/msg/PoseArray[gz.msgs.Pose_V" \
	        "/ouster/points@sensor_msgs/msg/PointCloud2[gz.msgs.PointCloudPacked" \
	        "/clock@rosgraph_msgs/msg/Clock[gz.msgs.Clock"
}


ola-qgc() {
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

compare_params() {
  if [ "$#" -ne 2 ]; then
    echo "Usage: compare_params file1.params file2.params"
    return 1
  fi

  awk '
  function abs(x) { return x < 0 ? -x : x }
  NR==FNR { a[$3] = $4; next }
  ($3 in a) {
    diff = $4 - a[$3]
    if (abs(diff) > 1e-5) {
      printf "%s: %s -> %s\n", $3, a[$3], $4
    }
  }
  ' "$1" "$2"
}
