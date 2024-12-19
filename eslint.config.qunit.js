const pluginQunit = require('eslint-plugin-qunit')

module.exports = {
  files: ['**/*Spec.{js,ts,tsx,jsx}'],
  plugins: {qunit: pluginQunit},
  languageOptions: {
    globals: {
      deepEqual: true,
      equal: true,
      module: true,
      notDeepEqual: true,
      notEqual: true,
      notOk: true,
      notStrictEqual: true,
      ok: true,
      propEqual: true,
      QUnit: true,
      raises: true,
      sandbox: true,
      sinon: true,
      strictEqual: true,
      test: true,
      throws: true,
    },
  },
  rules: {
    'no-useless-escape': 'off',
    'qunit/no-only': 'error',
    'qunit/no-skip': 'warn',
    'qunit/require-expect': 'warn',
  },
}
