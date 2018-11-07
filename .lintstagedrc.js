const filesToCheck = require('./.prettierwhitelist.js')

const config = {}

filesToCheck.forEach(glob => config[glob] = ['eslint --fix', 'git add'])

module.exports = config
