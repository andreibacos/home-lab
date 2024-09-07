#!/bin/bash
if [ "$ENABLE_DEBUG" == "true" ]; then
  echo "Entering debug mode..."
  sleep 999999999999
  exit 0
fi

check_env_var() {
  if [ -z "$2" ]
  then
    >&2 echo "ERR: environment variable $1 is not set"
    exit 1
  fi

  echo "$1 = $2"
}

check_env_var PORT "${PORT-}"
check_env_var RCON_PORT "${RCON_PORT-}"
check_env_var MAP "${MAP-}"
check_env_var ADMIN_PASSWORD "${ADMIN_PASSWORD-}"
check_env_var CLUSTER_ID "${CLUSTER_ID-}"
check_env_var UPDATE_ON_START "${UPDATE_ON_START-}"
check_env_var SESSION_NAME "${SESSION_NAME-}"

export STEAM_COMPAT_DATA_PATH="/home/steam/arkserver/steamapps/compatdata/2430930"
export STEAM_COMPAT_CLIENT_INSTALL_PATH="/home/steam/Steam/"

cat <<EOF > /home/steam/arkserver/rcon
#!/bin/bash
/usr/local/bin/rcon-cli --port $RCON_PORT --password $ADMIN_PASSWORD \$1
EOF
chmod +x /home/steam/arkserver/rcon

trap "/usr/bin/rcon saveworld" SIGTERM SIGINT SIGQUIT SIGHUP ERR

CLUSTER_DIR=/home/steam/cluster
STEAM_DIR=/opt/steamcmd
GAMESERVER_DIR=/home/steam/arkserver
ASA_BINARY_DIR="$GAMESERVER_DIR/ShooterGame/Binaries/Win64"
ASA_BINARY_NAME="ArkAscendedServer.exe"
ASA_PLUGIN_BINARY_NAME="AsaApiLoader.exe"
ASA_PLUGIN_LOADER_ARCHIVE_NAME=$(basename $ASA_BINARY_DIR/AsaApi_*.zip)
ASA_PLUGIN_LOADER_ARCHIVE_PATH="$ASA_BINARY_DIR/$ASA_PLUGIN_LOADER_ARCHIVE_NAME"
ASA_PLUGIN_BINARY_PATH="$ASA_BINARY_DIR/$ASA_PLUGIN_BINARY_NAME"
LAUNCH_BINARY_NAME="$ASA_BINARY_NAME"
ASA_START_PARAMS="$MAP?listen?Port=$PORT?SessionName=\"$SESSION_NAME\"?RCONPort=$RCON_PORT?RCONEnabled=True?ServerAdminPassword=$ADMIN_PASSWORD -clusterid=$CLUSTER_ID -ClusterDirOverride=$CLUSTER_DIR"

if [ -n "$CUSTOM_SERVER_ARGS" ]; then
    ASA_START_PARAMS="$ASA_START_PARAMS $CUSTOM_SERVER_ARGS"
fi

if [ -n "$MODS" ]; then
    ASA_START_PARAMS="$ASA_START_PARAMS -mods=$MODS"
fi

if [ "$UPDATE_ON_START" == "true" ] || [ -f $ASA_BINARY_DIR/$LAUNCH_BINARY_NAME ]; then
    # download/update server files
    cd $STEAM_DIR
    ./steamcmd.sh +force_install_dir $GAMESERVER_DIR +login anonymous +app_update 2430930 validate +quit
fi

# install proton compat game data
if [ ! -d "$STEAM_COMPAT_DATA_PATH" ]; then
    mkdir -p "$STEAM_COMPAT_DATA_PATH"
    cp -r /usr/local/bin/files/share/default_pfx "$STEAM_COMPAT_DATA_PATH"
fi

echo "Start ARK Server using parameters: $ASA_START_PARAMS"

cd "$ASA_BINARY_DIR"

# unzip the asa plugin api archive if it exists. delete it afterwards
if [ -f "$ASA_PLUGIN_LOADER_ARCHIVE_PATH" ]; then
  unzip -o $ASA_PLUGIN_LOADER_ARCHIVE_NAME
  rm $ASA_PLUGIN_LOADER_ARCHIVE_NAME
fi

if [ -f "$ASA_PLUGIN_BINARY_PATH" ]; then
  echo "Detected ASA Server API loader. Launching server through $ASA_PLUGIN_BINARY_NAME"
  LAUNCH_BINARY_NAME="$ASA_PLUGIN_BINARY_NAME"
fi

proton run $LAUNCH_BINARY_NAME $ASA_START_PARAMS
