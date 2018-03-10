module.exports = {
  transform: {
    '^.+\\.(js)$': 'babel-jest',
    '^.+\\.(css)$': '<rootDir>/jest-themeable-styles'
  },
  snapshotSerializers: [
    'enzyme-to-json/serializer'
  ],
  setupFiles: [
    './jest-env.js'
  ],
  coverageReporters: [
    'html',
    'text'
  ],
  collectCoverageFrom: [
    'src/**/*.js'
  ],
  coveragePathIgnorePatterns: [
    '<rootDir>/src/demo.js',
    '<rootDir>/src/i18n/flip-message.js'
  ],
  coverageThreshold: {
    global: {
      branches: 85,
      functions: 90,
      lines: 90,
      statements: 90
    }
  }
};
