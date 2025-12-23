#!/bin/bash
set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# 部署目录
DEPLOY_DIR="/opt/web-calculator"
COMPOSE_FILE="$DEPLOY_DIR/docker-compose.yml"
NGINX_CONF="$DEPLOY_DIR/nginx/default.conf"

# 获取当前活跃颜色
get_active_color() {
    if [ ! -f "$NGINX_CONF" ]; then
        echo "none"
        return
    fi
    
    if grep -q "^[[:space:]]*server app-blue:5001" "$NGINX_CONF" && ! grep -q "^[[:space:]]*#.*server app-blue:5001" "$NGINX_CONF"; then
        echo "blue"
    elif grep -q "^[[:space:]]*server app-green:5002" "$NGINX_CONF" && ! grep -q "^[[:space:]]*#.*server app-green:5002" "$NGINX_CONF"; then
        echo "green"
    else
        echo "unknown"
    fi
}

# 等待服务健康
wait_for_health() {
    local color=$1
    local port=$2
    local max_attempts=30
    local attempt=1
    
    log "等待 ${color} 版本健康检查..."
    
    while [ $attempt -le $max_attempts ]; do
        if docker exec "webcalc-${color}" curl -sf "http://localhost:${port}/health" > /dev/null 2>&1; then
            log "${color} 版本健康检查通过"
            return 0
        fi
        
        log "等待 ${color} 版本就绪... (${attempt}/${max_attempts})"
        sleep 5
        attempt=$((attempt + 1))
    done
    
    error "${color} 版本健康检查超时"
    return 1
}

# 切换流量
switch_traffic() {
    local new_color=$1
    
    log "切换到 ${new_color} 版本"
    
    # 备份配置
    cp "$NGINX_CONF" "${NGINX_CONF}.bak"
    
    if [ "$new_color" = "blue" ]; then
        # 切换到blue
        sed -i 's/^[[:space:]]*#.*server app-blue:5001/server app-blue:5001/' "$NGINX_CONF"
        sed -i 's/^[[:space:]]*server app-green:5002/# server app-green:5002/' "$NGINX_CONF"
    else
        # 切换到green
        sed -i 's/^[[:space:]]*server app-blue:5001/# server app-blue:5001/' "$NGINX_CONF"
        sed -i 's/^[[:space:]]*#.*server app-green:5002/server app-green:5002/' "$NGINX_CONF"
    fi
    
    # 重新加载nginx
    docker-compose -f "$COMPOSE_FILE" exec -T nginx nginx -s reload
    
    # 验证切换
    local active_color=$(get_active_color)
    if [ "$active_color" = "$new_color" ]; then
        log "成功切换到 ${new_color} 版本"
        return 0
    else
        error "切换失败，当前活跃: ${active_color}"
        return 1
    fi
}

# 部署新版本
deploy() {
    local new_image=$1
    
    log "开始蓝绿部署"
    log "新镜像: $new_image"
    
    cd "$DEPLOY_DIR"
    
    # 获取当前活跃颜色
    local current_color=$(get_active_color)
    local new_color
    
    if [ "$current_color" = "blue" ]; then
        new_color="green"
    elif [ "$current_color" = "green" ]; then
        new_color="blue"
    else
        # 首次部署
        new_color="blue"
        current_color="green"
    fi
    
    log "当前活跃: ${current_color}, 部署新版本到: ${new_color}"
    
    # 更新环境变量
    if [ "$new_color" = "blue" ]; then
        sed -i "s|BLUE_IMAGE=.*|BLUE_IMAGE=$new_image|" .env
    else
        sed -i "s|GREEN_IMAGE=.*|GREEN_IMAGE=$new_image|" .env
    fi
    
    # 拉取镜像
    log "拉取新镜像..."
    docker-compose pull "app-${new_color}"
    
    # 启动新版本
    log "启动 ${new_color} 版本..."
    docker-compose up -d "app-${new_color}"
    
    # 等待健康检查
    if wait_for_health "$new_color" "500$([ "$new_color" = "blue" ] && echo 1 || echo 2)"; then
        # 切换流量
        if switch_traffic "$new_color"; then
            # 停止旧版本
            log "停止 ${current_color} 版本..."
            docker-compose stop "app-${current_color}" 2>/dev/null || true
            docker-compose rm -f "app-${current_color}" 2>/dev/null || true
            
            log "部署成功！"
            echo "✅ 部署完成，当前活跃版本: ${new_color}"
            return 0
        else
            error "流量切换失败"
            return 1
        fi
    else
        error "新版本健康检查失败，执行回滚"
        # 回滚：停止新版本
        docker-compose stop "app-${new_color}" 2>/dev/null || true
        docker-compose rm -f "app-${new_color}" 2>/dev/null || true
        
        # 恢复nginx配置
        if [ -f "${NGINX_CONF}.bak" ]; then
            cp "${NGINX_CONF}.bak" "$NGINX_CONF"
            docker-compose exec -T nginx nginx -s reload
        fi
        
        return 1
    fi
}

# 主函数
main() {
    local new_image="$1"
    
    if [ -z "$new_image" ]; then
        error "请提供镜像名称"
        exit 1
    fi
    
    deploy "$new_image"
}

main "$@"