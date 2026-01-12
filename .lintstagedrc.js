module.exports = {
  '*.{js,jsx,ts,tsx}': ['eslint --fix', 'biome format --fix', 'git add'],
  'Jenkinsfile*': () => [], // Skip linting Groovy pipeline files
}
