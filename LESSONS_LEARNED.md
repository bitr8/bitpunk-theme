# Lessons Learned

## 2025-01-06: Gemini Image Generation Skill

### Heredocs Break Auto-Approve
- Claude Code bug #11932: heredoc/multiline commands cannot be auto-approved
- Solution: Added `-p "prompt"` flag to gemini-image.sh for single-line commands
- Pattern `Bash(~/.claude/skills/gemini-images/gemini-image.sh:*)` now works

### Context Optimization
- Don't display images with Read tool in terminal - wastes context
- Just list filenames; user views in Dolphin/file manager
- Run image generation with `run_in_background: true`, don't block waiting
- Launch multiple generations in parallel in single message

### OLED/Dark Wallpapers
- Cannot effectively darken a bright image after generation (ImageMagick creates artifacts)
- Must generate dark from the start with explicit prompts:
  - "CRITICAL: 70% pure black void (#000000)"
  - "Neon as accent lighting, not overwhelming"
  - "Deep shadows dominate, high contrast"
- Include exact hex codes for theme colors in prompts

### Gemini Billing
- Subscription (Ultra/Pro) and API are completely separate systems
- Subscription applies to: Gemini web app, Gemini CLI
- API applies to: Direct API calls (Python SDK)
- gemini CLI OAuth tokens cannot be used by Python SDK
- For Python SDK OAuth: need `gcloud auth application-default login`

## 2026-01-06: Subagent Model Selection

### Debugger Should Use Sonnet, Not Opus
- Opus over-investigates simple bugs, burning excessive tokens
- Example: 3M tokens for a JSON parsing bug (Sonnet would use ~50K)
- Opus tested 80+ permutations of stdin/TTY/subshell combinations
- Updated `~/.claude/CLAUDE.md` to specify Sonnet for debugger agent

### Gemini CLI -q Flag Bug
- Root cause: `Loaded cached credentials.` output to stdout breaks JSON parsing
- Fix: `sed -n '/^{/,/^}/p'` to extract JSON block before jq
- Lesson: CLI tools may emit non-JSON status messages to stdout

### Leonardo Script Hardening (from Codex + Gemini reviews)
- Add HTTP status checking to curl (curl returns 0 on 4xx/5xx)
- Include unique IDs in filenames to prevent race conditions
- Use `mktemp` + `trap` for temp files
- Validate inputs before arithmetic operations
- Add retry logic around API polling loops

### Leonardo Parallel Execution (Claude Code)
- Without `--no-wait`, script polls until complete - but Claude's background bash timeout (~2min) may kill it mid-poll
- Generation still completes on Leonardo's server - just lose the download
- **Solution**: Always use `--no-wait`, then manually check status and download:
  ```bash
  # Queue jobs (returns generation IDs)
  leonardo-generate.sh generate -p "prompt" --no-wait  # → abc123

  # Check status
  leonardo-generate.sh status abc123 | jq -r '.generations_by_pk | "\(.status) \(.generated_images[0].url)"'

  # Download when COMPLETE
  curl -sL "<url>" -o output.jpg
  ```
- Updated `~/.claude/skills/leonardo-ai/SKILL.md` with this workflow
