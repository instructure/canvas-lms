module.exports = {
  '*.{js,ts,tsx}': ['eslint --fix', 'git add'],
  '*.{ts,tsx}': ['tsc-files -p tsconfig.json --noEmit']
}
