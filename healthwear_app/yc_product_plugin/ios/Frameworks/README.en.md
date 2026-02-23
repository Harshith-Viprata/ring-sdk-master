# 当程序archive遇到Validation failed

'''
'Invalid Executable. The executable 'Runner.app/Frameworks/RTKLEFoundation.framework/ RTKLEFoundation' contains bitcode. (ID: 8ceb7a04-cef5-43a1-9902-0b889aa31a70)
和Validation failed
Invalid Executable. The executable 'Runner.app/Frameworks/RTKOTASDK.framework/ RTKOTASDK' contains bitcode. (ID: c2a09af1-1c9f-474b-9fdd-6d7a3cd4a154)
'''

## 处理方案 通过**run_commands.sh文件运行shell脚本解决**。脚本里面分别到'RTKLEFoundation.framework'和'RTKOTASDK.frameword'文件目录下运行命令。
-    script里面运行。
- 具体逻辑可以看run script和run_commands文件

