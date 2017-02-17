/*
* This file can be used to convey information to other eslint files inside
* Canvas.
*/

module.exports = {
  globals: {
    "ENV": true
  },
  plugins: [
    "promise"
  ],
  // 0 - off, 1 - warning, 2 - error
  rules: {
    "class-methods-use-this": [0],
    "comma-dangle": [2, "only-multiline"],
    "func-names": [0],
    "max-len": [1, {"code": 140}],
    "no-continue": [0],
    "no-plusplus": [0],
    "no-underscore-dangle": [0],
    "no-unused-vars": [2, { "argsIgnorePattern": "^_"}],
    "object-curly-spacing": [0],
    "semi": [0],
    "space-before-function-paren": [2, "always"],
    "import/no-amd": [0],

    // allows 'i18n!webzip_exports' and 'compiled/foo/bar'
    "import/no-extraneous-dependencies": [0],
    "import/named": [2],
    "import/no-unresolved": [0],
    "import/no-webpack-loader-syntax": [0],

    "import/extensions": [1, { "js": "never", "jsx": "never", "json": "always" }],
    "promise/avoid-new": [0],
  }
};
