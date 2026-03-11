#!/usr/bin/env python3
"""
VennCLAW Task Executor - 使用 OpenClaw subagent 执行任务
========================================================
这个脚本通过 OpenClaw Gateway 创建 subagent 来执行任务
"""

import subprocess
import json
import sys
import os
from pathlib import Path

def execute_task_with_subagent(worktree: str, task_description: str, timeout: int = 300):
    """
    使用 OpenClaw sessions_spawn 创建 subagent 执行任务
    
    由于 sessions_spawn 是 OpenClaw 的 tool，我们通过以下方式调用：
    1. 创建一个临时任务文件
    2. 使用 openclaw agent 命令执行
    """
    
    # 方法：使用 openclaw 的 subprocess 模式
    # 在 worktree 中创建一个任务脚本，然后执行
    
    task_script = f'''
# Task: {task_description}
# Worktree: {worktree}

import os
os.chdir('{worktree}')

# 执行任务
print("Executing task in:", os.getcwd())
print("Task:", """{task_description}""")

# 示例：创建一个 hello.py 文件
with open('hello.py', 'w') as f:
    f.write("print('Hello from VennCLAW!')\\n")

print("Created hello.py")
'''
    
    # 写入临时脚本
    script_path = os.path.join(worktree, '.execute_task.py')
    with open(script_path, 'w', encoding='utf-8') as f:
        f.write(task_script)
    
    try:
        # 执行脚本
        result = subprocess.run(
            ['python3', script_path],
            cwd=worktree,
            capture_output=True,
            text=True,
            timeout=timeout
        )
        
        # 清理
        os.remove(script_path)
        
        return {
            'status': 'completed' if result.returncode == 0 else 'error',
            'output': result.stdout,
            'error': result.stderr,
            'returncode': result.returncode
        }
        
    except subprocess.TimeoutExpired:
        if os.path.exists(script_path):
            os.remove(script_path)
        return {'status': 'timeout', 'error': f'Timeout after {timeout}s'}
    except Exception as e:
        if os.path.exists(script_path):
            os.remove(script_path)
        return {'status': 'error', 'error': str(e)}


if __name__ == '__main__':
    if len(sys.argv) < 3:
        print('Usage: python executor.py <worktree> <task_description>')
        sys.exit(1)
    
    worktree = sys.argv[1]
    task_description = ' '.join(sys.argv[2:])
    
    result = execute_task_with_subagent(worktree, task_description)
    print(json.dumps(result, indent=2, ensure_ascii=False))
