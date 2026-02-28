#!/bin/bash

# KROK 1: Synchronizacja i środowisko
echo "Synchronizacja zegara..."
sudo hwclock -s
source /opt/ros/humble/setup.bash
source install/setup.bash

export WAYLAND_DISPLAY=
export GDK_BACKEND=x11

echo "Rozpoczynam mapowanie (start od zera)."

# Czyścimy plik tymczasowy. Dzięki temu przy wciśnięciu ENTER, 
# skrypt zapisujący będzie wiedział, że to nowa mapa i poprosi o nazwę.
> /tmp/current_slam_map.txt

# --- URUCHAMIANIE WĘZŁÓW ---
echo "Uruchamiam LiDAR..."
ros2 launch sllidar_ros2 sllidar_a2m12_launch.py &

echo "Konfiguruję transformacje (TF)..."  # to do zmiany przy odometrii
ros2 run tf2_ros static_transform_publisher 0 0 0 0 0 0 odom base_link  &
ros2 run tf2_ros static_transform_publisher 0 0 0 0 0 0 base_link laser  &

echo "Uruchamiam Model Robota (URDF)..."
ros2 run robot_state_publisher robot_state_publisher ~/lidar_slam_ws/moj_robot.urdf &

echo "Uruchamiam SLAM Toolbox..."
ros2 run slam_toolbox async_slam_toolbox_node --ros-args \
  --params-file ~/lidar_slam_ws/mapper_params_mapping.yaml \
  -p use_sim_time:=false &

echo "Uruchamiam RViz2..."
ros2 run rviz2 rviz2 -d ~/lidar_slam_ws/moja_konfiguracja2.rviz  &

# --- PĘTLA STEROWANIA Z KLAWIATURY ---
echo "================================================================"
echo " SYSTEM MAPOWANIA DZIAŁA."
echo " [ENTER] - Zapisz mape (jeśli to nowa mapa, zostaniesz poproszony o nazwę)"
echo " [ESC]   - Zamknij program i wyłącz lidar"
echo "================================================================"

while true; do

    read -rsn1 key

    # Jeśli wciśnięto ENTER 
    if [[ "$key" == "" ]]; then
        echo -e "\n Wykryto [ENTER]. Uruchamiam zapis..."
        
        ./zapisz_mape.sh
        
        echo -e "\n================================================================"
        echo " [ENTER] - Zapisz postęp mapy ponownie"
        echo " [ESC]   - Zamknij program i wyłącz lidar"
        echo "================================================================"
        
    # Jeśli wciśnięto ESC
    elif [[ "$key" == $'\e' ]]; then
        echo -e "\n Wykryto [ESC]. Rozpoczynam wyłączanie..."
        break 
    fi
done

# --- ZAMYKANIE PROCESÓW ---
echo "Zamykanie procesów..."
pkill -INT -f "sllidar_node"
pkill -INT -f "sllidar_a2m12_launch"
sleep 3
kill -INT $(jobs -p)
sleep 2
pkill -9 -f "rviz2"
pkill -9 -f "slam_toolbox"

echo "Gotowe! Programy wyłączone."
exit 0