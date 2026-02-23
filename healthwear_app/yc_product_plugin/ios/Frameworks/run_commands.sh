#!/bin/bash

echo "传递的参数数量: $#"
echo "第一个参数: $1"
echo "第二个参数: $2"

# 检查是否在终端中运行
#if [ -z "$TERM_PROGRAM" ]; then
#    # 不在终端中运行，使用 open 命令在新终端中打开脚本
#    open -a Terminal.app "$0"
#    exit 0
#fi

# 检查是否传入了两个参数
if [ $# -ne 2 ]; then
    echo "错误：请提供两个路径作为参数。"
    read -p "按回车键退出..."
    exit 1
fi

# 获取传入的两个路径
path1="$1"
path2="$2"

# 执行第一个命令，切换到第一个路径
cd "$path1"
# 检查命令执行状态
if [ $? -ne 0 ]; then
    echo "命令1（切换到 $path1 目录）执行失败"
    read -p "按回车键退出..."
    exit 1
fi

# 执行第二个命令，检查 RTKLEFoundation 的 Bitcode
otool -l RTKLEFoundation | grep __LLVM | wc -l
if [ $? -ne 0 ]; then
    echo "命令2（检查 RTKLEFoundation 的 Bitcode）执行失败"
    read -p "按回车键退出..."
    exit 1
fi

# 执行第三个命令，移除 RTKLEFoundation 的 Bitcode
xcrun bitcode_strip -r RTKLEFoundation -o RTKLEFoundation
if [ $? -ne 0 ]; then
    echo "命令3（移除 RTKLEFoundation 的 Bitcode）执行失败"
    read -p "按回车键退出..."
    exit 1
fi

# 执行第四个命令，切换到第二个路径
cd "$path2"
if [ $? -ne 0 ]; then
    echo "命令4（切换到 $path2 目录）执行失败"
    read -p "按回车键退出..."
    exit 1
fi

# 执行第五个命令，检查 RTKOTASDK 的 Bitcode
otool -l RTKOTASDK | grep __LLVM | wc -l
if [ $? -ne 0 ]; then
    echo "命令5（检查 RTKOTASDK 的 Bitcode）执行失败"
    read -p "按回车键退出..."
    exit 1
fi

# 执行第六个命令，移除 RTKOTASDK 的 Bitcode
xcrun bitcode_strip -r RTKOTASDK -o RTKOTASDK
if [ $? -ne 0 ]; then
    echo "命令6（移除 RTKOTASDK 的 Bitcode）执行失败"
    read -p "按回车键退出..."
    exit 1
fi

echo "所有命令执行成功"
#read -p "按回车键退出..."
exit 0 
    
