module.exports = {
  '*.{js,jsx,ts,tsx}': ['oxlint --fix', 'biome format --fix', 'git add'],
  'Jenkinsfile*': () => [], // Skip linting Groovy pipeline files
}
