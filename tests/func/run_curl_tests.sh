#!/bin/bash
# 功能测试脚本

set -e

echo "开始功能测试..."
echo "======================"

# 修改这里：将 web-calc 改为 localhost
APP_URL="http://localhost:5000"
MAX_WAIT=30
WAIT_INTERVAL=2
count=0

echo "等待服务启动..."
until curl -s -f "$APP_URL/health" > /dev/null 2>&1 || [ $count -eq $MAX_WAIT ]; do
    echo "等待服务启动... ($count/$MAX_WAIT)"
    sleep $WAIT_INTERVAL
    count=$((count + WAIT_INTERVAL))
done

if [ $count -eq $MAX_WAIT ]; then
    echo "错误: 服务在${MAX_WAIT}秒内未启动"
    exit 1
fi

echo "服务已启动，开始测试..."
echo ""

# 测试1: 健康检查
echo "测试1: 健康检查"
response=$(curl -s "$APP_URL/health")
echo "响应: $response"
if echo "$response" | grep -q "healthy"; then
    echo "✓ 健康检查通过"
else
    echo "✗ 健康检查失败"
    exit 1
fi

echo ""

# 测试2: 加法
echo "测试2: 加法 (2 + 3)"
response=$(curl -s "$APP_URL/add/2&3")
echo "响应: $response"
if echo "$response" | grep -q '"result":5'; then
    echo "✓ 加法测试通过"
else
    echo "✗ 加法测试失败"
    exit 1
fi

echo ""

# 测试3: 乘法
echo "测试3: 乘法 (4 × 5)"
response=$(curl -s "$APP_URL/multiply/4&5")
echo "响应: $response"
if echo "$response" | grep -q '"result":20'; then
    echo "✓ 乘法测试通过"
else
    echo "✗ 乘法测试失败"
    exit 1
fi

echo ""

# 测试4: 无效输入
echo "测试4: 无效输入处理"
response=$(curl -s -o /dev/null -w "%{http_code}" "$APP_URL/add/abc&xyz")
echo "HTTP状态码: $response"
if [ "$response" -eq 400 ]; then
    echo "✓ 无效输入处理通过"
else
    echo "✗ 无效输入处理失败"
    exit 1
fi

echo ""
echo "======================"
echo "所有功能测试通过! ✓"

# 生成测试报告
echo "功能测试报告" > functional-test-report.txt
echo "生成时间: $(date)" >> functional-test-report.txt
echo "测试URL: $APP_URL" >> functional-test-report.txt
echo "测试结果: 全部通过" >> functional-test-report.txt
echo "测试用例: 4" >> functional-test-report.txt
echo "通过: 4" >> functional-test-report.txt
echo "失败: 0" >> functional-test-report.txt

cat functional-test-report.txt