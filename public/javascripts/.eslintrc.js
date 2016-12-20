module.exports = {
  root: true, // Makes sure we don't get additional settings (such as ES2015+ specifics)
  extends: 'airbnb-base/legacy', // Only ES5 and below
  rules: require('../../.eslintrc.common.js').rules, // Pull in our common rules
  globals: require('../../.eslintrc.common.js').globals // Pull in our common globals
};
