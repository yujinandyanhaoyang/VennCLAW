#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
OpenClaw Agent Manager - Zoe (编排层核心)
基于 Datawhale 教程 + OpenCode 集成
========================================================
作者：Venn | 更新：2026-03-08
========================================================
"""

import os
import json
import subprocess
import uuid
from datetime import datetime
from pathlib import Path
from typing import Optional, Dict, Any, List
from dataclasses import dataclass
from enum import Enum


class AgentType(Enum):
    OPENCODE = "opencode"      # 主力开发 - 使用已配置的 OpenCode API
    CLAUDE_CODE = "claude-code"
    GEMINI = "gemini"


class TaskStatus(Enum):
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    NEEDS_HUMAN = "needs-human"


@dataclass
class Task:
    id: str
    description: str
    agent_type: AgentType
    repo_path: str
    worktree: str
    branch: str
    status: TaskStatus
    started_at: int
    tmux_session: Optional[str] = None

    def to_dict(self) -> Dict:
        return {
            "id": self.id,
            "description": self.description,
            "agent_type": self.agent_type.value,
            "status": self.status.value,
            "started_at": self.started_at,
            "tmux_session": self.tmux_session,
            "branch": self.branch
        }


class TaskTracker:
    def __init__(self, log_file: str):
        self.log_file = Path(log_file)
        self.log_file.parent.mkdir(parents=True, exist_ok=True)
        if not self.log_file.exists():
            self.log_file.touch()

    def append(self, task: Task):
        with open(self.log_file, 'a', encoding='utf-8') as f:
            f.write(json.dumps(task.to_dict(), ensure_ascii=False) + '\n')

    def get_all_tasks(self) -> List[Task]:
        tasks = []
        if not self.log_file.exists():
            return tasks
        with open(self.log_file, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    data = json.loads(line)
                    task = Task(
                        id=data['id'],
                        description=data['description'],
                        agent_type=AgentType(data['agent_type']),
                        worktree='',
                        branch=data['branch'],
                        status=TaskStatus(data['status']),
                        started_at=data['started_at'],
                        tmux_session=data.get('tmux_session')
                    )
                    tasks.append(task)
                except Exception as e:
                    print(f'Error parsing task log: {e}')
        return tasks

    def update_task(self, task_id: str, updates: Dict[str, Any]):
        all_tasks = self.get_all_tasks()
        updated = False
        new_entries = []
        for task_data in all_tasks:
            if task_data.id == task_id:
                for key, value in updates.items():
                    if hasattr(Task, key):
                        setattr(task_data, key, value)
                updated = True
            new_entries.append(task_data)
        with open(self.log_file, 'w', encoding='utf-8') as f:
            for task in new_entries:
                f.write(json.dumps(task.to_dict(), ensure_ascii=False) + '\n')
        return updated if updated else None


class GitWorktreeManager:
    def __init__(self, repo_path: str):
        self.repo_path = Path(repo_path).resolve()

    def create_worktree(self, worktree_name: str, base_branch: str = 'main') -> str:
        worktree_path = self.repo_path.parent / worktree_name
        if worktree_path.exists():
            raise ValueError(f'Worktree exists: {worktree_name}')
        cmd = ['git', 'worktree', 'add', str(worktree_path), '-b', worktree_name.replace('/', '-'), base_branch]
        result = subprocess.run(cmd, cwd=self.repo_path, capture_output=True, text=True)
        if result.returncode != 0:
            raise RuntimeError(f'Create worktree failed: {result.stderr}')
        return str(worktree_path)


class OpencodeExecutor:
    @staticmethod
    def run_opencode(project_path: str, task_description: str):
        """启动 OpenCode 执行任务"""
        cmd = ['opencode', 'run', '--project', project_path, task_description]
        process = subprocess.Popen(
            cmd,
            cwd=project_path,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True
        )
        return process


class OpenClawOrchestrator:
    def __init__(self, repo_path: str):
        self.repo_path = Path(repo_path).resolve()
        self.task_tracker = TaskTracker(str(Path(repo_path) / '.openclaw-agents' / 'task-tracker.jsonl'))
        self.git_manager = GitWorktreeManager(str(repo_path))
        self.opencode_executor = OpencodeExecutor()
        self.context_dir = Path(repo_path) / 'src/openclaw/context'
        self.business_context = self._load_business_context()

    def _load_business_context(self) -> Dict[str, Any]:
        context = {'meeting_notes': [], 'customer_data': {}}
        meeting_notes_dir = self.context_dir / 'meeting-notes'
        if meeting_notes_dir.exists():
            for file in meeting_notes_dir.glob('*.md'):
                try:
                    with open(file, 'r', encoding='utf-8') as f:
                        context['meeting_notes'].append({
                            'file': file.name,
                            'content': f.read()[:200]
                        })
                except Exception as e:
                    print(f'Error reading meeting note: {e}')
        return context

    def recommend_agent(self, description: str) -> AgentType:
        return AgentType.OPENCODE

    def _build_prompt_with_context(self, description: str) -> str:
        full_prompt = f'[TASK]\n{description}\n\n'
        if self.business_context['meeting_notes']:
            full_prompt += '[RELATED NOTES]\n'
            for note in self.business_context['meeting_notes'][-3:]:
                full_prompt += f"- {note['file']}: {note['content']}\n"
        return full_prompt

    def create_task(self, description: str) -> Optional[Task]:
        print(f'\n[N] Analyzing task: {description[:80]}...')
        
        enhanced_prompt = self._build_prompt_with_context(description)
        agent_type = self.recommend_agent(enhanced_prompt)
        print(f'[+] Recommended Agent: {agent_type.value} (using OpenCode)')
        
        task_id = f'feat-{uuid.uuid4().hex[:12]}'
        try:
            worktree_path = self.git_manager.create_worktree(task_id)
            branch = task_id.replace('feat-', 'feat/')
            print(f'[OK] Created isolated workspace: {worktree_path}')
        except Exception as e:
            print(f'[X] Failed to create worktree: {e}')
            return None
        
        task = Task(
            id=task_id,
            description=enhanced_prompt,
            agent_type=agent_type,
            repo_path=str(self.repo_path),
            worktree=worktree_path,
            branch=branch,
            status=TaskStatus.PENDING,
            started_at=int(datetime.now().timestamp() * 1000)
        )
        self.task_tracker.append(task)
        print(f'[OK] Task created successfully: {task_id}')
        return task

    def execute_task(self, task: Task) -> bool:
        print(f'\n[RUNNING] Executing task: {task.id}')
        print(f'[INFO] Description:\n{task.description[:200]}...')
        
        try:
            process = self.opencode_executor.run_opencode(
                project_path=task.worktree,
                task_description=task.description
            )
            print(f'[OK] OpenCode started (PID: {process.pid})')
            
            task.status = TaskStatus.RUNNING
            self.task_tracker.update_task(task.id, {'status': 'running'})
            return True
                
        except Exception as e:
            print(f'[X] Failed to start OpenCode: {e}')
            task.status = TaskStatus.FAILED
            self.task_tracker.update_task(task.id, {'status': 'failed'})
            return False

    def monitor_task(self, task_id: str) -> Dict[str, Any]:
        task = self._get_task_by_id(task_id)
        if not task:
            return {'error': f'Task not found: {task_id}'}
        return {
            'task_id': task_id,
            'status': task.status.value,
            'description': task.description[:100],
            'started_at': datetime.fromtimestamp(task.started_at / 1000).strftime('%Y-%m-%d %H:%M'),
            'context_loaded': len(self.business_context.get('meeting_notes', [])) > 0
        }

    def _get_task_by_id(self, task_id: str) -> Optional[Task]:
        all_tasks = self.task_tracker.get_all_tasks()
        for task in all_tasks:
            if task.id == task_id:
                return task
        return None


def main():
    import sys
    
    if len(sys.argv) < 2:
        print('Usage: python agent-manager.py <command> [args]')
        print('Commands:')
        print('  create-task <description>      - Create new task')
        print('  run <task-id>                  - Execute task')
        print('  status <task-id>               - Check task status')
        print('  monitor                        - Monitor all tasks')
        print('')
        print('Example:')
        print('  python agent-manager.py create-task "Implement user login feature with JWT auth"')
        return
    
    command = sys.argv[1]
    repo_path = Path(__file__).parent.resolve()
    orchestrator = OpenClawOrchestrator(str(repo_path))
    
    if command == 'create-task':
        if len(sys.argv) < 3:
            print('[X] Please provide task description')
            return
        description = ' '.join(sys.argv[2:])
        task = orchestrator.create_task(description)
        if task:
            print(f'\n[TASK DETAILS]')
            print(f'  ID: {task.id}')
            print(f'  Description: {task.description[:150]}...')
            print(f'  Agent: {task.agent_type.value}')
            print(f'  Worktree: {task.worktree}')
            print(f'  Branch: {task.branch}')
            print(f'\n[NOTE] Next: python agent-manager.py run {task.id}')

    elif command == 'run':
        if len(sys.argv) < 3:
            print('[X] Please provide task ID')
            return
        task_id = sys.argv[2]
        task = orchestrator._get_task_by_id(task_id)
        if task and task.status == TaskStatus.PENDING:
            orchestrator.execute_task(task)
        else:
            print(f'[X] Task not found or invalid status: {task_id}')
            if task:
                print(f'[INFO] Current status: {task.status.value}')

    elif command == 'status':
        if len(sys.argv) < 3:
            print('[X] Please provide task ID')
            return
        task_id = sys.argv[2]
        result = orchestrator.monitor_task(task_id)
        print(json.dumps(result, indent=2, ensure_ascii=False))

    elif command == 'monitor':
        all_tasks = orchestrator.task_tracker.get_all_tasks()
        print(f'\n[ALL TASKS] Total: {len(all_tasks)}')
        if not all_tasks:
            print('  No tasks yet')
        else:
            for task in all_tasks:
                print(f'\n{"="*70}')
                print(f'  ID: {task.id} [{task.status.value}]')
                print(f'  Description: {task.description[:70]}...')
                print(f'  Agent: {task.agent_type.value}')
                start_time = datetime.fromtimestamp(task.started_at / 1000)
                print(f'  Started: {start_time.strftime("%Y-%m-%d %H:%M")}')

    else:
        print(f'[X] Unknown command: {command}')


if __name__ == '__main__':
    main()
