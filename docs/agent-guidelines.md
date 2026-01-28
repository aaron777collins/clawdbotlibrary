# Agent Problem-Solving Guidelines

> Best practices for AI agents tackling complex tasks efficiently.

## 🧠 Core Principles

### 1. Use Sub-Agents for Complex Work

Don't try to do everything in one session. Spawn sub-agents for:
- **Parallel tasks** - Multiple independent operations
- **Isolated work** - Tasks that need separate context
- **Long-running jobs** - Background processing
- **Different expertise** - Specialized sub-tasks

```bash
# Example: Spawn a sub-agent for a background task
sessions_spawn task="Research X and report back" model="claude-sonnet"
```

### 2. Size the Model to the Task

Not every task needs the most powerful model:

| Task Type | Suggested Model |
|-----------|-----------------|
| Complex reasoning, architecture | claude-opus |
| General coding, analysis | claude-sonnet |
| Simple edits, formatting | claude-haiku |
| Quick lookups, basic tasks | Smallest available |

**Rule of thumb**: Start with a smaller model; escalate if needed.

### 3. Think Through Dependencies First

Before starting ANY complex task:

1. **List all dependencies** - What needs to exist/run first?
2. **Identify blockers** - What could prevent success?
3. **Check prerequisites** - Are all tools/services available?
4. **Plan the order** - What sequence makes sense?

### 4. Consider Contingencies

Ask yourself:
- What if step X fails?
- What if the service is down?
- What if the file doesn't exist?
- What's the fallback plan?

**Build in error handling** - Don't assume happy path.

## 🔄 Problem-Solving Workflow

```
1. UNDERSTAND
   └─→ What exactly needs to be done?
   └─→ What are the success criteria?

2. ANALYZE
   └─→ What dependencies exist?
   └─→ What could go wrong?
   └─→ What resources are needed?

3. PLAN
   └─→ Break into sub-tasks
   └─→ Identify parallel opportunities
   └─→ Assign appropriate models/agents

4. EXECUTE
   └─→ Spawn sub-agents for parallel work
   └─→ Monitor progress
   └─→ Handle errors gracefully

5. VERIFY
   └─→ Did it work?
   └─→ Are there edge cases?
   └─→ Document what was learned
```

## 📋 Pre-Task Checklist

Before starting a complex task, answer:

- [ ] Do I understand the full scope?
- [ ] Have I identified all dependencies?
- [ ] Do I know what could fail?
- [ ] Should this be broken into sub-tasks?
- [ ] Is this the right model for this task?
- [ ] Do I have a fallback plan?

## 💡 Sub-Agent Best Practices

### When to Spawn
- Task takes >5 minutes
- Task is independent of main conversation
- Multiple tasks can run in parallel
- Task needs different context/expertise

### How to Spawn
```bash
# Background task with auto-report
sessions_spawn task="Do X, Y, Z and report results" 

# Specify model for efficiency
sessions_spawn task="Simple formatting task" model="claude-haiku"

# Check on running agents
sessions_list activeMinutes=30
```

### Monitoring
- Check `sessions_list` for active sub-agents
- Use `sessions_history` to see what they did
- Sub-agents announce completion automatically

## 🚨 Common Mistakes to Avoid

1. **Starting without planning** - Always think before doing
2. **Using opus for everything** - Match model to task complexity
3. **Ignoring dependencies** - Check prerequisites first
4. **No error handling** - Plan for failures
5. **Doing everything sequentially** - Parallelize when possible
6. **Not documenting** - Write down what you learned

## 📝 Example: Complex Task Breakdown

**Task**: "Set up browser automation on a new server"

**Bad approach**: Start installing things randomly

**Good approach**:
```
1. DEPENDENCIES
   - Need: Ubuntu, Python, Chrome, Xvfb, Fluxbox
   - Check: Is this a fresh server? What's installed?

2. CONTINGENCIES
   - Chrome install might fail → use apt fallback
   - Xvfb might not start → check display number
   - Fluxbox might crash → add restart logic

3. SUB-TASKS (can parallelize)
   - Sub-agent 1: Install system packages
   - Sub-agent 2: Set up Python environment
   - Main agent: Write config files

4. VERIFICATION
   - Test each component
   - Take screenshot to verify
   - Document any issues
```

---

*Remember: Think first, plan second, execute third.*
