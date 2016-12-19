module.exports = {
  "env": {
    "es6": true,
    "amd": true,
    "browser": true
  },
  "extends": "airbnb",
  "globals": {
    "ENV": true
  },
  "parserOptions": {
    "ecmaVersion": 7,
    "ecmaFeatures": {
      "experimentalObjectRestSpread": true,
      "jsx": true
    },
    "sourceType": "module"
  },
  "parser": "babel-eslint",
  "rules": require('./.eslintrc.common.js').rules
};
