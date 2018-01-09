module.exports = {
  "moduleNameMapper": {
    "^i18n!(.*$)": "<rootDir>/jest/i18nTransformer.js",
    "^compiled/(.*)$": "<rootDir>/app/coffeescripts/$1"
  },
  "roots": [
    "app/jsx"
  ],
  "moduleDirectories": [
    "node_modules",
    "public/javascripts"
  ],
  "transform": {
    "^i18n": "<rootDir>/jest/i18nTransformer.js",
    "^.+\\.jsx?$": "babel-jest"
  }
}
