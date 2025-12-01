# Jules | Async Coding Agent

## Environment setup script

```
# Install GitHub CLI & Auth with PAT
sudo apt update
sudo apt install gh
echo "$GH_PAT" | gh auth login --with-token
gh auth status

# Install Supabase MCP

npx -y @supabase/mcp-server-supabase@latest \
  --project-ref 'apqvyyphlrtmuyjznmuq'
```
