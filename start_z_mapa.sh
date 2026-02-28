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
ros2 run rviz2 rviz2 -d ~/lidar_slam_ws/moja_konfiguracja.rviz &

# KROK 5: SLAM (Edycja) - Główny proces
echo "Uruchamiam SLAM Toolbox..."
ros2 run slam_toolbox async_slam_toolbox_node --ros-args \
  --params-file ~/lidar_slam_ws/mapper_params_edit.yaml \
  -p use_sim_time:=false