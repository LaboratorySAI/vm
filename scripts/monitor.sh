#!/bin/bash
# ==============================================================================
# OpenCode Monitor & Self-Heal Script
# ==============================================================================
# This script monitors the OpenCode and OpenChamber services, automatically
# restarting them if they crash. It also manages the tunnel connection.
#
# Usage: ./monitor.sh <tunnel_provider> <timeout_minutes> <tunnel_url>
#
# Arguments:
#   tunnel_provider: "ngrok" or "cloudflare"
#   timeout_minutes: Auto-shutdown timeout in minutes
#   tunnel_url: Initial tunnel URL (passed from workflow)
# ==============================================================================

set -uo pipefail

TUNNEL_PROVIDER="${1:-cloudflare}"
TIMEOUT_MINUTES="${2:-300}"
INITIAL_URL="${3:-}"

echo "=============================================="
echo "OpenCode Monitor & Self-Heal"
echo "=============================================="
echo "Tunnel Provider: $TUNNEL_PROVIDER"
echo "Timeout: $TIMEOUT_MINUTES minute(s)"
echo "Initial URL: $INITIAL_URL"
echo "=============================================="
echo ""

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------
OPENCODE_PORT=8080
OPENCHAMBER_PORT=9090
START_TIME=$(date +%s)
TIMEOUT_SECONDS=$((TIMEOUT_MINUTES * 60))
CURRENT_URL="$INITIAL_URL"

# ------------------------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------------------------

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

check_port() {
    local port=$1
    lsof -i :"$port" > /dev/null 2>&1
}

get_remaining_time() {
    local elapsed=$(($(date +%s) - START_TIME))
    local remaining=$((TIMEOUT_SECONDS - elapsed))
    echo $remaining
}

format_time() {
    local seconds=$1
    local minutes=$((seconds / 60))
    local hours=$((minutes / 60))
    minutes=$((minutes % 60))
    
    if [ $hours -gt 0 ]; then
        echo "${hours}h ${minutes}m"
    else
        echo "${minutes}m"
    fi
}

# ------------------------------------------------------------------------------
# Service Management
# ------------------------------------------------------------------------------

restart_opencode() {
    log "Restarting OpenCode on port $OPENCODE_PORT..."
    pkill -f "opencode web" 2>/dev/null || true
    sleep 2
    nohup stdbuf -oL opencode web --port $OPENCODE_PORT >> opencode.log 2>&1 &
    sleep 5
    
    if check_port $OPENCODE_PORT; then
        log "OpenCode restarted successfully"
        return 0
    else
        log "ERROR: Failed to restart OpenCode"
        return 1
    fi
}

restart_openchamber() {
    log "Restarting OpenChamber on port $OPENCHAMBER_PORT..."
    pkill -f "openchamber" 2>/dev/null || true
    sleep 2
    nohup stdbuf -oL openchamber --port $OPENCHAMBER_PORT >> openchamber.log 2>&1 &
    sleep 5
    
    if check_port $OPENCHAMBER_PORT; then
        log "OpenChamber restarted successfully"
        return 0
    else
        log "ERROR: Failed to restart OpenChamber"
        return 1
    fi
}

restart_tunnel() {
    log "Restarting tunnel ($TUNNEL_PROVIDER)..."
    
    if [ "$TUNNEL_PROVIDER" = "ngrok" ]; then
        pkill -f "ngrok" 2>/dev/null || true
        sleep 2
        nohup ngrok http 127.0.0.1:$OPENCHAMBER_PORT --log=stdout > tunnel.log 2>&1 &
        sleep 10
        
        # Get new URL
        CURRENT_URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | jq -r '.tunnels[0].public_url // empty')
    else
        pkill -f "cloudflared" 2>/dev/null || true
        sleep 2
        nohup cloudflared tunnel --url http://127.0.0.1:$OPENCHAMBER_PORT > tunnel.log 2>&1 &
        sleep 15
        
        # Get new URL
        CURRENT_URL=$(grep -o 'https://[-a-z0-9.]*trycloudflare.com' tunnel.log 2>/dev/null | tail -n 1)
    fi
    
    if [ -n "$CURRENT_URL" ]; then
        log "Tunnel restarted successfully"
        log "NEW URL: $CURRENT_URL"
        echo ""
        echo "=============================================="
        echo "NEW ACCESS URL: $CURRENT_URL"
        echo "=============================================="
        echo ""
        return 0
    else
        log "ERROR: Failed to get tunnel URL"
        return 1
    fi
}

check_tunnel() {
    if [ "$TUNNEL_PROVIDER" = "ngrok" ]; then
        pgrep -f "ngrok" > /dev/null 2>&1
    else
        pgrep -f "cloudflared" > /dev/null 2>&1
    fi
}

# ------------------------------------------------------------------------------
# Graceful Shutdown
# ------------------------------------------------------------------------------

shutdown() {
    log "Initiating graceful shutdown..."
    
    # Kill all services
    pkill -f "opencode" 2>/dev/null || true
    pkill -f "openchamber" 2>/dev/null || true
    pkill -f "ngrok" 2>/dev/null || true
    pkill -f "cloudflared" 2>/dev/null || true
    
    log "All services stopped"
    exit 0
}

# Trap signals for graceful shutdown
trap shutdown SIGTERM SIGINT

# ==============================================================================
# Main Monitoring Loop
# ==============================================================================

log "Starting monitoring loop..."
echo ""

# Status display interval (every 5 minutes = 300 seconds)
LAST_STATUS_TIME=0
STATUS_INTERVAL=300

while true; do
    REMAINING=$(get_remaining_time)
    
    # Check for timeout
    if [ $REMAINING -le 0 ]; then
        log "Timeout reached. Initiating graceful shutdown..."
        shutdown
    fi
    
    # Periodic status update (every 5 minutes)
    CURRENT_TIME=$(date +%s)
    if [ $((CURRENT_TIME - LAST_STATUS_TIME)) -ge $STATUS_INTERVAL ]; then
        echo ""
        echo "=============================================="
        log "Status Update"
        echo "Time remaining: $(format_time $REMAINING)"
        echo "Access URL: $CURRENT_URL"
        echo "=============================================="
        echo ""
        LAST_STATUS_TIME=$CURRENT_TIME
    fi
    
    # Check OpenCode
    if ! check_port $OPENCODE_PORT; then
        log "OpenCode not responding on port $OPENCODE_PORT"
        restart_opencode
    fi
    
    # Check OpenChamber
    if ! check_port $OPENCHAMBER_PORT; then
        log "OpenChamber not responding on port $OPENCHAMBER_PORT"
        restart_openchamber
    fi
    
    # Check Tunnel
    if ! check_tunnel; then
        log "Tunnel process not running"
        restart_tunnel
    fi
    
    # Show last line of openchamber log (activity indicator)
    if [ -f "openchamber.log" ]; then
        tail -n 1 openchamber.log 2>/dev/null || true
    fi
    
    # Sleep before next check
    sleep 5
done
