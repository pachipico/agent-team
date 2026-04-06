mkdir -p ~/.claude/agents/orchestrator
cp "$(pwd)/agents/orchestrator-CLAUDE.md" ~/.claude/agents/orchestrator/CLAUDE.md

mkdir -p ~/.claude/agents/planner
cp "$(pwd)/agents/planner-CLAUDE.md" ~/.claude/agents/planner/CLAUDE.md

mkdir -p ~/.claude/agents/worker
cp "$(pwd)/agents/worker-CLAUDE.md" ~/.claude/agents/worker/CLAUDE.md

mkdir -p ~/.claude/agents/researcher
cp "$(pwd)/agents/researcher-CLAUDE.md" ~/.claude/agents/researcher/CLAUDE.md

mkdir -p ~/.claude/agents/tester
cp "$(pwd)/agents/tester-CLAUDE.md" ~/.claude/agents/tester/CLAUDE.md


mkdir -p ~/.claude/commands/agent-team
cp -rv "$(pwd)/commands/"* ~/.claude/commands/agent-team
