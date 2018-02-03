module.exports = {
  "moduleNameMapper": {
    "^i18n!(.*$)": "<rootDir>/jest/i18nTransformer.js",
    "^compiled/(.*)$": "<rootDir>/app/coffeescripts/$1"
  },
  "roots": [
    "app/jsx"
  ],
  setupFiles: [
    '<rootDir>/jest/jest-setup.js'
  ],
  "transform": {
    "^i18n": "<rootDir>/jest/i18nTransformer.js",
    "^.+\\.jsx?$": "babel-jest"
  }
}
