#!/bin/bash

# Health Monitor Script
# Shows detailed status of the llama.cpp server during startup

echo "=== Devstral Server Health Monitor ==="
echo "Monitoring llama.cpp server health status..."
echo "Press Ctrl+C to stop monitoring"
echo ""

# Function to get and display health status
get_health_status() {
    local container_name="llama-cpp-devstral"
    
    # Check if container is running
    if ! docker ps --format "table {{.Names}}" | grep -q "^$container_name$"; then
        echo "❌ Container not running"
        return 1
    fi
    
    # Get health status from docker
    local health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null)
    
    # Get detailed health message
    local health_message=$(docker exec "$container_name" /app/health-check.sh 2>/dev/null)
    
    # Display status with appropriate emoji
    case "$health_status" in
        "healthy")
            case "$health_message" in
                "DOWNLOADING:"*)
                    echo "⏬ $health_message"
                    ;;
                "WAITING:"*)
                    echo "⏳ $health_message"
                    ;;
                "LOADING:"*)
                    echo "🔄 $health_message"
                    ;;
                "SERVING:"*)
                    echo "✅ $health_message"
                    ;;
                *)
                    echo "✅ HEALTHY: $health_message"
                    ;;
            esac
            ;;
        "unhealthy")
            echo "❌ UNHEALTHY: $health_message"
            ;;
        "starting")
            echo "🚀 STARTING: Container initializing..."
            ;;
        *)
            echo "❓ UNKNOWN: $health_status"
            ;;
    esac
}

# Main monitoring loop
while true; do
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -n "[$timestamp] "
    get_health_status
    sleep 10
done
