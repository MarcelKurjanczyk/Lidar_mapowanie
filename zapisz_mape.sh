#!/bin/bash

source /opt/ros/humble/setup.bash
source ~/lidar_slam_ws/install/setup.bash

MAPS_DIR="$HOME/lidar_slam_ws/maps"
TEMP_FILE="/tmp/current_slam_map.txt"
CURRENT_MAP_NAME=$(cat "$TEMP_FILE" 2>/dev/null)

if [ -z "$CURRENT_MAP_NAME" ]; then
    echo "Podaj nazwe dla nowej mapy:"
    read map_name
    
    CURRENT_MAP_NAME=$(echo "$map_name" | tr -d ' ')
    echo "$CURRENT_MAP_NAME" > "$TEMP_FILE"
else
    echo "Wykryto prace na wczytanej mapie: $CURRENT_MAP_NAME"
fi

MAP_DIR_PATH="$MAPS_DIR/$CURRENT_MAP_NAME"
mkdir -p "$MAP_DIR_PATH"
FULL_MAP_PATH="$MAP_DIR_PATH/$CURRENT_MAP_NAME"

echo "Zapisywanie do: $MAP_DIR_PATH/"

# [1/2] Serializacja (Dane dla SLAM)
echo "Zapisywanie sesji (.data i .posegraph)..."
if ros2 service call /slam_toolbox/serialize_map slam_toolbox/srv/SerializePoseGraph "{filename: '$FULL_MAP_PATH'}"; then
    echo "Sesja zapisana."
else
    echo "BLAD: Nie udalo sie zapisac sesji!"
    exit 1
fi

# [2/2] Obraz (Dane dla Nav2)
echo "Zapisywanie obrazu (.pgm i .yaml)..."
if ros2 service call /slam_toolbox/save_map slam_toolbox/srv/SaveMap "{name: {data: '$FULL_MAP_PATH'}}"; then
    echo "Obraz mapy zapisany."
else
    echo "BLAD: Nie udalo sie zapisac obrazu!"
    exit 1
fi

echo "ZAPIS ZAKONCZONY"