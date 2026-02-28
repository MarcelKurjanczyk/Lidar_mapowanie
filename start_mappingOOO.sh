#!/bin/bash

# KROK 1: Synchronizacja i środowisko
echo "Synchronizacja zegara..."
sudo hwclock -s
source /opt/ros/humble/setup.bash
source install/setup.bash

export WAYLAND_DISPLAY=
export GDK_BACKEND=x11

# --- LOGIKA TWORZENIA NOWEJ MAPY ---
MAPS_DIR="$HOME/lidar_slam_ws/maps"
mkdir -p "$MAPS_DIR"

echo "[SYSTEM] Rozpoczynam mapowanie (start od zera)."
MAP_PARAM_ARGS="-p map_start_at_dock:=true"

# Czyścimy plik tymczasowy. Dzięki temu przy wciśnięciu ENTER, 
# skrypt zapisujący będzie wiedział, że to nowa mapa i poprosi o nazwę.
> /tmp/current_slam_map.txt

# --- URUCHAMIANIE WĘZŁÓW ---
echo "Uruchamiam LiDAR..."
ros2 launch sllidar_ros2 sllidar_a2m12_launch.py &

echo "Konfiguruję transformacje (TF)..."
ros2 run tf2_ros static_transform_publisher 0 0 0 0 0 0 odom base_link > /dev/null 2>&1 &
ros2 run tf2_ros static_transform_publisher 0 0 0 0 0 0 base_link laser > /dev/null 2>&1 &

echo "Uruchamiam SLAM Toolbox..."
ros2 run slam_toolbox async_slam_toolbox_node --ros-args \
  --params-file ~/lidar_slam_ws/mapper_params_mapping.yaml \
  -p use_sim_time:=false $MAP_PARAM_ARGS > /dev/null 2>&1 &

echo "Czekam na ustabilizowanie węzłów..."
sleep 2

echo "Uruchamiam RViz2..."
ros2 run rviz2 rviz2 -d ~/lidar_slam_ws/moja_konfiguracja.rviz > /dev/null 2>&1 &

# --- PĘTLA STEROWANIA Z KLAWIATURY ---
echo "================================================================"
echo " SYSTEM MAPOWANIA DZIAŁA."
echo " [ENTER] - Zapisz postęp mapy"
echo " [ESC]   - Zamknij program i wyłącz lasery"
echo "================================================================"

while true; do
    # Oczekiwanie na wciśnięcie jednego klawisza (ukryte wejście)
    read -rsn1 key
    
    # Jeśli wciśnięto ENTER (pusty znak w tym trybie)
    if [[ "$key" == "" ]]; then
        echo -e "\n[SYSTEM] Wykryto [ENTER]. Uruchamiam zapis..."
        
        # Uruchamia skrypt zapisujący w tym samym oknie
        ./zapisz_mape.sh
        
        echo -e "\n================================================================"
        echo " [ENTER] - Zapisz postęp mapy ponownie"
        echo " [ESC]   - Zamknij program i wyłącz lasery"
        echo "================================================================"
        
    # Jeśli wciśnięto ESC (znak ucieczki)
    elif [[ "$key" == $'\e' ]]; then
        echo -e "\n[SYSTEM] Wykryto [ESC]. Rozpoczynam wyłączanie..."
        break # Przerywa pętlę i idzie do zamykania procesów
    fi
done

# --- ZAMYKANIE PROCESÓW ---
echo "Zamykanie procesów i zatrzymywanie silnika..."
pkill -INT -f "sllidar_node"
pkill -INT -f "sllidar_a2m12_launch"
sleep 3
kill -INT $(jobs -p) 2>/dev/null
sleep 2
pkill -9 -f "rviz2"
pkill -9 -f "slam_toolbox"

echo "Gotowe! Programy wyłączone."
exit 0