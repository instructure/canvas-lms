const pluginJest = require('eslint-plugin-jest')

module.exports = {
  files: [
    '**/*.{test,spec}.{js,ts,tsx,jsx}',
    '**/test-utils.js',
    '**/assertions.js',
    '**/testHelpers.js',
    '**/__tests__/*',
    '**/__mocks__/*',
    'jest/**',
    'ui/shared/stub-env/index.js',
    'ui/boot/initializers/__tests__/configureDateTimeWithI18n.t3st.js',
  ],
  plugins: {jest: pluginJest},
  languageOptions: {
    globals: {
      ...pluginJest.environments.globals.globals,
      global: true,
    },
  },
  rules: {
    // jest/no-disabled-tests, jest/no-focused-tests, jest/valid-expect → oxlint
    'jest/no-identical-title': 'warn',
    'jest/prefer-to-have-length': 'warn',
  },
}
