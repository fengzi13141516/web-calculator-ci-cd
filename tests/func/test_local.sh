#!/bin/bash
echo "本地功能测试开始..."
echo "======================"

# 测试健康检查
echo "1. 测试健康检查:"
curl -s "http://localhost:5000/health"
echo ""

# 测试加法
echo "2. 测试加法 (2 + 3):"
curl -s "http://localhost:5000/add/2&3"
echo ""

# 测试乘法
echo "3. 测试乘法 (4 × 5):"
curl -s "http://localhost:5000/multiply/4&5"
echo ""

# 测试无效输入
echo "4. 测试无效输入 (abc + xyz):"
curl -s -o /dev/null -w "HTTP状态码: %{http_code}\n" "http://localhost:5000/add/abc&xyz"
echo ""

echo "======================"
echo "手动测试完成！"
