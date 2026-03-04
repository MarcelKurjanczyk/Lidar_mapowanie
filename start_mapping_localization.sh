#!/bin/bash

echo "Synchronizacja zegara..."
sudo hwclock -s
source /opt/ros/humble/setup.bash
source install/setup.bash

export WAYLAND_DISPLAY=
export GDK_BACKEND=x11

MAPS_DIR="$HOME/lidar_slam_ws/maps"

echo "========================================="
echo " WYBIERZ MAPĘ DO LOKALIZACJI"
echo "========================================="
echo -e "Dostępne mapy:"
ls -d "$MAPS_DIR"/*/ 2>/dev/null | xargs -n 1 basename
echo "-----------------------------------------"
read -p "Podaj nazwę mapy: " map_name

MAP_PATH="$MAPS_DIR/$map_name/$map_name"

if [ ! -f "${MAP_PATH}.posegraph" ]; then
    echo "BŁĄD Nie znaleziono plików mapy w folderze $MAPS_DIR/$map_name/"
    exit 1
fi

echo "Wczytywanie mapy z folderu: $map_name"

echo "Uruchamiam LiDAR..."
ros2 launch sllidar_ros2 sllidar_a2m12_launch.py &

echo "Konfiguruję transformacje (TF)..." # to do zmiany przy odometrii
ros2 run tf2_ros static_transform_publisher 0 0 0 0 0 0 odom base_link &
ros2 run tf2_ros static_transform_publisher 0 0 0 0 0 0 base_link laser  &

echo "Uruchamiam Model Robota (URDF)..."
ros2 run robot_state_publisher robot_state_publisher ~/lidar_slam_ws/moj_robot.urdf &

echo "Uruchamiam SLAM Toolbox w trybie LOKALIZACJI..."
ros2 run slam_toolbox localization_slam_toolbox_node --ros-args \
  --params-file ~/lidar_slam_ws/mapper_params_map_loc.yaml \
  -p use_sim_time:=false \
  -p map_file_name:=$MAP_PATH &

echo "Uruchamiam RViz2..."
ros2 run rviz2 rviz2 -d ~/lidar_slam_ws/moja_konfiguracja2.rviz &

# --- PĘTLA STEROWANIA Z KLAWIATURY ---

echo "================================================================"
echo " SYSTEM LOKALIZACJI I MAPOWANIA DZIAŁA."
echo " [ENTER] - Zapisz mape"
echo " [ESC]   - Zamknij program i wyłącz lidar"
echo "================================================================"

while true; do
    read -rsn1 key
    # ENTER 
    if [[ "$key" == "" ]]; then
        echo -e "\n Uruchamiam zapis..."
        
        ./zapisz_mape.sh
        
        echo -e "\n================================================================"
        echo " [ENTER] - Zapisz postęp mapy ponownie"
        echo " [ESC]   - Zamknij program i wyłącz lidar"
        echo "================================================================"
    # ESC
    elif [[ "$key" == $'\e' ]]; then
        echo -e "\n Rozpoczynam wyłączanie..."
        break 
    fi
done

echo "Zamykanie procesów..."
pkill -INT -f "sllidar_node"
pkill -INT -f "sllidar_a2m12_launch"
sleep 3
kill -INT $(jobs -p) 2>/dev/null
sleep 2
pkill -9 -f "rviz2"
pkill -9 -f "slam_toolbox"

echo "Programy wyłączone."
exit 0