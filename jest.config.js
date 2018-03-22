module.exports = {
  moduleNameMapper: {
    '^i18n!(.*$)': '<rootDir>/jest/i18nTransformer.js',
    '^compiled/(.*)$': '<rootDir>/app/coffeescripts/$1',
    '^jsx/(.*)$': '<rootDir>/app/jsx/$1'
  },
  roots: ['app/jsx'],
  moduleDirectories: [
    'node_modules',
    'public/javascripts',
    'public/javascripts/vendor'
  ],
  setupFiles: [
    'jest-localstorage-mock',
    '<rootDir>/jest/jest-setup.js'
  ],
  testMatch: [
    '**/__tests__/**/?(*.)(spec|test).js'
  ],
  testResultsProcessor: 'jest-junit',
  transform: {
    '^i18n': '<rootDir>/jest/i18nTransformer.js',
    '^.+\\.jsx?$': 'babel-jest'
  }
}
