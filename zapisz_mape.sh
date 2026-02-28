#!/bin/bash
source /opt/ros/humble/setup.bash
source ~/lidar_slam_ws/install/setup.bash

MAPS_DIR="$HOME/lidar_slam_ws/maps"
# Odczytujemy, jaką mapę aktualnie obsługuje główny skrypt
CURRENT_MAP_NAME=$(cat /tmp/current_slam_map.txt 2>/dev/null)

echo "================================================================"

if [ -z "$CURRENT_MAP_NAME" ]; then
    echo " Tworzysz NOWĄ mapę. Czy chcesz ją zapisać? (t/n)"
    read -p " Wybór: " save_choice
    
    if [[ "$save_choice" != "t" && "$save_choice" != "T" ]]; then
        echo " Zapis anulowany."
        exit 0
    fi
    
    read -p " Podaj nazwę dla nowej mapy: " map_name
    CURRENT_MAP_NAME="$map_name"
    
    # Zapisujemy nową nazwę do pliku, żeby przy kolejnym kliknięciu w tej sesji już nie pytał
    echo "$CURRENT_MAP_NAME" > /tmp/current_slam_map.txt
else
    echo " Wykryto pracę na wczytanej mapie: $CURRENT_MAP_NAME"
fi

# Przygotowanie unikalnego folderu dla tej mapy
MAP_DIR_PATH="$MAPS_DIR/$CURRENT_MAP_NAME"
mkdir -p "$MAP_DIR_PATH"
FULL_MAP_PATH="$MAP_DIR_PATH/$CURRENT_MAP_NAME"

echo "----------------------------------------------------------------"
echo " TRWA ZAPISYWANIE DO: $MAP_DIR_PATH/"
echo "----------------------------------------------------------------"

echo "[1/2] Zapisywanie sesji (.data i .posegraph)..."
ros2 service call /slam_toolbox/serialize_map slam_toolbox/srv/SerializePoseGraph "{filename: '$FULL_MAP_PATH'}"

sleep 1

echo "[2/2] Zapisywanie obrazu (.pgm i .yaml)..."
ros2 service call /slam_toolbox/save_map slam_toolbox/srv/SaveMap "{name: {data: '$FULL_MAP_PATH'}}"

echo "================================================================"
echo " ZAPIS ZAKOŃCZONY POMYŚLNIE!"
echo "================================================================"