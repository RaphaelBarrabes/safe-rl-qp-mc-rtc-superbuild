#!/usr/bin/env bash

echo "-- Setting up the container --"
echo "-- Checking devcontainer requirements --"
if [ "$BUILD_VERSION" = "devcontainer" ]; then
  # By default, WORKSPACE_SRC_DIR / WORKSPACE_BUILD_DIR / WORKSPACE_INSTALL_DIR
  # (src/, build/, install/, siblings of superbuild/) live inside the
  # container only and are lost on rebuild. If you added bind mounts for
  # them in devcontainer.json for persistence, they'll show up here instead.
  if [ ! -d /home/vscode/superbuild ]; then
    echo "⚠️ The /home/vscode/superbuild directory is missing!"
    echo "➡️ Please add the following to your devcontainer.json to mount it:"
    echo '"workspaceMount": "source=${localWorkspaceFolder},target=/home/vscode/superbuild,type=bind",'
    echo '"workspaceFolder": "/home/vscode/superbuild"'
  fi
fi

echo "-- Sourcing additional files --"
# If the install folder is present, source it
if [ -f $WORKSPACE_INSTALL_DIR/setup_mc_rtc.sh ]; then
  echo "--> Sourcing mc-rtc-superbuild environment from $WORKSPACE_INSTALL_DIR/setup_mc_rtc.sh"
  source $WORKSPACE_INSTALL_DIR/setup_mc_rtc.sh
fi

# If the image was built with a custom entrypoint, source it as well
if [ -f ~/.docker-custom-entrypoint.sh ]; then
  echo '--> Using custom entrypoint ~/.docker-custom-entrypoint.sh'
  source ~/.docker-custom-entrypoint.sh
fi

echo "-- Setting up environment variables --"
# Makes GNUPG ask for password in the terminal
export GPG_TTY=$(tty)
echo "GPG_TTY=$GPG_TTY"

if [ "$BUILD_VERSION" = "devcontainer" ]; then
  echo "-- ccache --"
  echo "ccache is configured as follows:"
  # Copy cache from the image to the local repository
  # This ensures that cache is kept between successive container runs
  echo "Synching local .ccache with the pre-built cache in the docker image"
  echo "CCACHE_DIR=$CCACHE_DIR"
  rsync -a ~/.cache/ccache/ ~/.ccache-superbuild --exclude='**.tmp.*' --ignore-existing
  export CCACHE_DIR=~/.ccache-superbuild
  ccache -sv
fi

# Add checkbox emoji
echo "✅ Container setup complete"

echo ""
echo ""
echo "-- Welcome to mc-rtc-superbuild image for Ubuntu `lsb_release -cs`! --"
echo ""
echo "All the tools needed to work with mc_rtc are pre-installed in this image."
echo "To build, use one of the proposed cmake presets:"
echo ""
cd ~/superbuild
cmake --list-presets
echo ""
echo '$ cmake --preset relwithdebinfo # configures cmake and install system dependencies'
echo ""
echo '$ cmake --build --preset relwithdebinfo'
echo '- clones projects in ~/src and builds all projects in the superbuild'
echo '- generates a build folder for the superbuild in ~/build/superbuild'
echo '- generates a build folder for all projects in ~/build/<project_name>'
echo
echo 'To update all projects in the superbuild, run:'
echo '$ cmake --build --preset relwithdebinfo --target update'
echo '$ cmake --build --preset relwithdebinfo'
echo
echo 'Projects are installed in ~/install'
echo
echo "Please refer to README.md for more information about the superbuild."
echo ""
echo "Handy aliases are already set up in this container:"
echo '  mc_build              - rebuild the superbuild'
echo '  mc_superbuild_config  - open ccmake to change build options (e.g. add a new robot)'
echo '  mc_update             - git pull + rebuild all projects'
echo '  mc_config             - open mc_rtc.yaml (robot/controller selection) in VS Code'
echo '  mc_rviz               - open the RViz interface'
echo ""
echo 'H1 is already built and ready to run — set it up with mc_config, then run: mc_mujoco --sync'
echo ""