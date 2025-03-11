#!/bin/bash

DB_DIR="/home/ykhadiri/data/db"
WORDPRESS_DIR="/home/ykhadiri/data/wordpress"

mkdir -p "$DB_DIR"
mkdir -p "$WORDPRESS_DIR"


docker-compose up -d