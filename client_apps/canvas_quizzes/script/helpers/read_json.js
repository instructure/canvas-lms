var fs = require('fs');

module.exports = function readJSON(filePath) {
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
};