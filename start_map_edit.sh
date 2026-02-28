#!/bin/bash

# KROK 1: Synchronizacja zegara WSL
echo "Synchronizacja zegara..."
sudo hwclock -s

# Odświeżenie środowiska
source /opt/ros/humble/setup.bash
source install/setup.bash

# KROK 2: Uruchomienie LiDARa w tle
echo "Uruchamiam LiDAR..."
ros2 launch sllidar_ros2 sllidar_a2m12_launch.py &

# KROK 3: Sztywne połączenie TF w tle
echo "Konfiguruję transformacje (TF)..."
ros2 run tf2_ros static_transform_publisher 0 0 0 0 0 0 odom base_link &
ros2 run tf2_ros static_transform_publisher 0 0 0 0 0 0 base_link laser &

# KROK 4: RViz2 w tle
echo "Uruchamiam RViz2..."
#ros2 run rviz2 rviz2 -d ~/lidar_slam_ws/moja_konfiguracja.rviz &
ros2 run rviz2 rviz2 -d ~/lidar_slam_ws/moja_konfiguracja2.rviz &

# KROK 5: SLAM (Edycja) w tle
echo "Uruchamiam SLAM Toolbox..."
ros2 run slam_toolbox async_slam_toolbox_node --ros-args \
  --params-file ~/lidar_slam_ws/mapper_params_edit.yaml \
  -p use_sim_time:=false &

# KROK 6: System kontroli zapisu
echo ""
echo "================================================================"
echo " UWAGA: ABY ZAPISAĆ WSZYSTKIE 4 PLIKI I WYJŚĆ, NACIŚNIJ [ENTER]"
echo "================================================================"

# Skrypt zatrzymuje się tutaj i czeka na wciśnięcie klawisza ENTER
read -p ""

echo ""
echo "[SYSTEM] Rozpoczynam zapisywanie sesji (.data i .posegraph)..."
ros2 service call /slam_toolbox/serialize_map slam_toolbox/srv/SerializePoseGraph "{filename: '/home/ubuntu22/lidar_slam_ws/moja_mapa'}"
sleep 1
echo "[SYSTEM] Rozpoczynam zapisywanie obrazu (.pgm i .yaml)..."
ros2 service call /slam_toolbox/save_map slam_toolbox/srv/SaveMap "{name: {data: '/home/ubuntu22/lidar_slam_ws/moja_mapa'}}"

echo "[SYSTEM] Zapis zakończony. Zamykanie procesów i zatrzymywanie silnika..."

# 1. Najpierw zatrzymujemy LiDAR (bezpiecznie, z sygnałem INT)
pkill -INT -f "sllidar_node"
pkill -INT -f "sllidar_a2m12_launch"
sleep 3

# 2. Zamykamy resztę środowiska ROS 2 (RViz, SLAM, TF)
kill -INT $(jobs -p) 2>/dev/null

echo "Czekam na ostateczne zamknięcie procesów w tle..."
sleep 2

# 3. Dobijamy ewentualne  (ale LiDAR jest już bezpiecznie zatrzymany)
pkill -9 -f "rviz2"
pkill -9 -f "slam_toolbox"

echo "Gotowe! LiDAR zatrzymany, a programy wyłączone."
exit 0