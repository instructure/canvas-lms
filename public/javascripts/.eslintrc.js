module.exports = Object.assign({
  root: true, // Makes sure we don't get additional settings (such as ES2015+ specifics)
  extends: 'airbnb-base/legacy', // Only ES5 and below
  "parserOptions": {
    "sourceType": "module"
  },
}, require('../../.eslintrc.common.js'))
