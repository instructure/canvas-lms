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
  reporters: [ "default", "jest-junit" ],
  setupFiles: [
    'jest-localstorage-mock',
    'jest-canvas-mock',
    '<rootDir>/jest/jest-setup.js'
  ],
  testMatch: [
    '**/__tests__/**/?(*.)(spec|test).js'
  ],

  coverageDirectory: '<rootDir>/coverage-jest/',

  transform: {
    '^i18n': '<rootDir>/jest/i18nTransformer.js',
    '^.+\\.jsx?$': 'babel-jest'
  }
}
