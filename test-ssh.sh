#!/bin/bash
echo "=== SSH连接测试 ==="
echo "服务器: $1"
echo "用户名: $2"
echo "私钥文件: $3"

ssh -o StrictHostKeyChecking=no -i "$3" "$2@$1" "
  echo '1. ✅ 成功连接到服务器'
  echo '2. 当前用户: \$(whoami)'
  echo '3. 系统信息: \$(uname -a)'
  echo '4. 磁盘空间:'
  df -h | grep -E 'Filesystem|/$'
  echo '5. 内存使用:'
  free -h
  echo '6. ✅ SSH连接测试完成'
"
