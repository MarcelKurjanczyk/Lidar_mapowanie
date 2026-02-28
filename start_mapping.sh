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
sleep 2

# KROK 3: Sztywne połączenie wszystkiego (TF) w tle
echo "Konfiguruję transformacje (TF)..."
ros2 run tf2_ros static_transform_publisher 0 0 0 0 0 0 odom base_link &
ros2 run tf2_ros static_transform_publisher 0 0 0 0 0 0 base_link laser &
sleep 2

# KROK 4: RViz2 w tle
echo "Uruchamiam RViz2..."
ros2 run rviz2 rviz2 
sleep 2

# KROK 5: Slam Toolbox (Tryb Brutalny) - Główny proces
echo "Uruchamiam SLAM Toolbox (Tryb Brutalny)..."
ros2 run slam_toolbox async_slam_toolbox_node --ros-args \
  -p use_sim_time:=false \
  -p odom_frame:=odom \
  -p base_frame:=base_link \
  -p transform_timeout:=5.0 \
  -p minimum_travel_distance:=0.0 \
  -p minimum_travel_heading:=0.0 \
  -p map_update_interval:=0.1