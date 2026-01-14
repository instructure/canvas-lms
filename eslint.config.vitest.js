const pluginVitestGlobals = require('eslint-plugin-vitest-globals')

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
  languageOptions: {
    globals: {
      ...pluginVitestGlobals.environments.env.globals,
      global: true,
    },
  },
  rules: {
    'react/no-deprecated': 'warn',
  },
}
