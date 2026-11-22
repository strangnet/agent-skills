#!/usr/bin/env bash
set -euo pipefail
cat > package.json <<'J'
{ "name": "shop", "type": "module", "scripts": { "test": "vitest run" },
  "devDependencies": { "typescript": "5.6.3", "vitest": "2.1.8" } }
J
cat > tsconfig.json <<'J'
{ "compilerOptions": { "strict": true, "module": "esnext", "moduleResolution": "bundler", "target": "es2022", "noEmit": true }, "include": ["src"] }
J
mkdir -p src
