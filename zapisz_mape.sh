#!/bin/bash

# Odświeżenie środowiska, żeby system widział usługi i typy wiadomości
source /opt/ros/humble/setup.bash
source ~/lidar_slam_ws/install/setup.bash

echo "================================================================"
echo " ROZPOCZYNAM ZAPIS MAPY Z SLAM TOOLBOX"
echo "================================================================"

# 1. Zapis sesji (pliki do wczytywania i edycji: .data i .posegraph)
echo "[1/2] Zapisywanie sesji (.data i .posegraph)..."
ros2 service call /slam_toolbox/serialize_map slam_toolbox/srv/SerializePoseGraph "{filename: '/home/ubuntu22/lidar_slam_ws/moja_mapa'}"

sleep 1

# 2. Zapis obrazu (pliki do podglądu i nawigacji: .pgm i .yaml)
echo "[2/2] Zapisywanie obrazu (.pgm i .yaml)..."
ros2 service call /slam_toolbox/save_map slam_toolbox/srv/SaveMap "{name: {data: '/home/ubuntu22/lidar_slam_ws/moja_mapa'}}"

echo "================================================================"
echo " ZAPIS ZAKOŃCZONY POMYŚLNIE!"
echo " Możesz teraz bezpiecznie wyłączyć główny skrypt (Ctrl+C)."
echo "================================================================"