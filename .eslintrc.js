module.exports = Object.assign({
  "env": {
    "es6": true,
    "amd": true,
    "browser": true
  },
  "extends": "airbnb",
  "parserOptions": {
    "ecmaVersion": 7,
    "ecmaFeatures": {
      "experimentalObjectRestSpread": true,
      "jsx": true
    },
    "sourceType": "module"
  },
  "parser": "babel-eslint",
}, require('./.eslintrc.common.js'))
