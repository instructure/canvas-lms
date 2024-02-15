/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

const path = require('path')

module.exports = {
  env: {
    es6: true,
    amd: true,
    browser: true,
  },
  extends: [
    'airbnb',
    'prettier/react',
    'plugin:jest/recommended',
    'plugin:prettier/recommended',
    'plugin:eslint-comments/recommended',
    'plugin:promise/recommended',
  ],
  parserOptions: {
    ecmaVersion: 2020,
    ecmaFeatures: {
      jsx: true,
    },
    sourceType: 'module',
  },
  parser: '@typescript-eslint/parser',

  globals: {
    ENV: true,
    JSX: true,
    INST: true,
    tinyMCE: true,
    tinymce: true,
    structuredClone: true,
  },
  plugins: [
    'promise',
    'import',
    'notice',
    'jest',
    'prettier',
    'jsx-a11y',
    'lodash',
    'react',
    'react-hooks',
    'babel',
    '@typescript-eslint',
  ],
  rules: {
    'no-cond-assign': ['error', 'except-parens'],

    // enable the react-hooks rules
    'react-hooks/rules-of-hooks': 'error',
    'react-hooks/exhaustive-deps': 'warn',

    // These come from our extended configurations, but we don't care about them
    camelcase: 'off', // because we have a ton of `const $user_name = $('#user_name')`
    'comma-dangle': 'off',
    'class-methods-use-this': 'off',
    'consistent-return': 'off',
    'default-case': 'off',
    eqeqeq: 'warn', // great goal! but since we do it 1061 times, downgrade AirBnB's 'error' to 'warn' :(
    'func-names': 'off',
    'global-require': 'off', // every time we did this, we meant to
    'guard-for-in': 'off',
    'max-classes-per-file': 'off',
    'no-continue': 'off',
    'no-else-return': 'off',
    'no-multi-assign': 'off',
    'no-nested-ternary': 'off',
    'no-new': 'off', // because we do `new SomeView()` all the time in Backbone just for the sideffects
    'no-param-reassign': 'off',
    'no-plusplus': 'off',
    'no-prototype-builtins': 'off',
    'no-return-assign': 'off',
    'no-underscore-dangle': 'off',
    'no-use-before-define': 'off',
    'object-shorthand': 'warn',
    '@typescript-eslint/no-use-before-define': [
      'error',
      {
        functions: false,
        classes: false,
        variables: false,
      },
    ],
    'no-useless-escape': 'off',
    'one-var': 'off',
    'prefer-destructuring': 'off',
    'prefer-rest-params': 'off',
    'prefer-template': 'off', // AirBnB says 'error', we don't care
    'eslint-comments/disable-enable-pair': ['error', {allowWholeFile: true}], // We are okay with turning rules off for the entirety of a file (though use it sparingly)
    'import/prefer-default-export': 'off',
    'jsx-a11y/label-has-for': 'off',
    'jsx-a11y/anchor-is-valid': ['error', {components: []}], // InstUI has special behavior around this
    'promise/always-return': 'off',
    'promise/catch-or-return': ['warn', {allowFinally: true}], // The recommendation is to error on this, but we downgrade it to a warning
    'promise/avoid-new': 'off',
    'promise/no-nesting': 'off',
    'react/jsx-no-target-blank': 'warn',
    'react/jsx-curly-brace-presence': 'warn',
    'react/destructuring-assignment': 'off',
    'react/forbid-prop-types': 'off', // AirBnB doesn't want you to use PropTypes.object, and we agree normally. But there are times where you just want to pass on an opaque object to something else and forcing people to make a PropTypes.shape for it doesn't add any value. People should still encourage each other to use PropTypes.shape normally, when it makes sense, in code-review but we're not going to -2 because of it.
    'react/no-typos': 'off',
    'react/sort-comp': 'off',
    'react/require-default-props': 'off',
    'react/prop-types': ['error', {skipUndeclared: true}],
    'react/default-props-match-prop-types': ['error', {allowRequiredDefaults: true}], // add the `allowRequiredDefaults: true` option to allow specifying something as a required prop (so you get propType error messages), but in case it's not present at runtime, I'll use `[]` as the default (so it is resilient)".
    'react/forbid-foreign-prop-types': ['error', {allowInPropTypes: true}], // You can refer to proptypes within proptypes, but you shouldn't use proptypes in actual app code of the component
    'react/jsx-boolean-value': [1, 'always'], // React recommends always passing values to props, see https://reactjs.org/docs/jsx-in-depth.html#props-default-to-true
    'react/jsx-no-bind': 'off',
    'react/jsx-props-no-spreading': 'off',
    'react/no-danger': 'off', // dangerouslySetInnerHTML is already pretty explicit on making you aware of its danger
    'react/no-render-return-value': 'warn', // In future versions of react this will fail
    'react/state-in-constructor': 'off',
    'react/static-property-placement': 'off',
    'react/no-unknown-property': 'warn',

    // don't restrict Math.pow for ** operator
    // ref: https://github.com/airbnb/javascript/blob/1f786e154f6c32385607e1688370d7f2d053f88f/packages/eslint-config-airbnb-base/rules/best-practices.js#L225
    'no-restricted-properties': [
      'error',
      {
        object: 'arguments',
        property: 'callee',
        message: 'arguments.callee is deprecated',
      },
      {
        object: 'global',
        property: 'isFinite',
        message: 'Please use Number.isFinite instead',
      },
      {
        object: 'self',
        property: 'isFinite',
        message: 'Please use Number.isFinite instead',
      },
      {
        object: 'window',
        property: 'isFinite',
        message: 'Please use Number.isFinite instead',
      },
      {
        object: 'global',
        property: 'isNaN',
        message: 'Please use Number.isNaN instead',
      },
      {
        object: 'self',
        property: 'isNaN',
        message: 'Please use Number.isNaN instead',
      },
      {
        object: 'window',
        property: 'isNaN',
        message: 'Please use Number.isNaN instead',
      },
      {
        property: '__defineGetter__',
        message: 'Please use Object.defineProperty instead.',
      },
      {
        property: '__defineSetter__',
        message: 'Please use Object.defineProperty instead.',
      },
    ],

    'no-restricted-syntax': [
      // This is here because we are turning off 2 items from what AirBnB cares about.
      'error',
      {
        selector: 'LabeledStatement',
        message:
          'Labels are a form of GOTO; using them makes code confusing and hard to maintain and understand.',
      },
      {
        selector: 'WithStatement',
        message:
          '`with` is disallowed in strict mode because it makes code impossible to predict and optimize.',
      },
    ],

    // These are discouraged, but allowed
    'no-console': 'warn',
    'jest/no-large-snapshots': 'warn',

    // These are things we care about
    'react/jsx-filename-extension': ['error', {extensions: ['jsx', 'tsx']}],
    'eslint-comments/no-unused-disable': 'error',
    'jest/no-disabled-tests': 'off',
    'import/extensions': [
      'error',
      'ignorePackages',
      {js: 'never', ts: 'never', jsx: 'never', tsx: 'never', coffee: 'never'},
    ],
    'import/no-commonjs': 'off', // This is overridden where it counts
    'import/no-extraneous-dependencies': 'off',
    'lodash/callback-binding': 'error',
    'lodash/collection-method-value': 'error',
    'lodash/collection-return': 'error',
    'lodash/no-extra-args': 'error',
    'lodash/no-unbound-this': 'error',
    'notice/notice': [
      'error',
      {
        templateFile: path.join(__dirname, 'config', 'copyright-template.js'),
        // purposely lenient so we don't automatically put our copyright notice on
        // top of something already copyrighted by someone else.
        mustMatch: 'Copyright ',
      },
    ],
    'no-unused-expressions': 'off', // the babel version allows optional chaining a?.b
    'babel/no-unused-expressions': ['error', {allowShortCircuit: true, allowTernary: true}],
    'prettier/prettier': 'warn',

    // Some rules need to be replaced with typescript versions to work with TS
    'no-redeclare': 'off',
    '@typescript-eslint/no-redeclare': 'error',
    'no-shadow': 'off',
    '@typescript-eslint/no-shadow': 'warn', // AirBnB says 'error', we downgrade to just 'warn'
    'no-unused-vars': 'off',
    '@typescript-eslint/no-unused-vars': [
      'warn',
      {
        argsIgnorePattern: '^_',

        // allows `const {propIUse, propIDontUseButDontWantToPassOn, ...propsToPassOn} = this.props`
        ignoreRestSiblings: true,
      },
    ],
    semi: 'off',
    '@typescript-eslint/semi': ['warn', 'never'],
  },
  settings: {
    'import/resolver': {
      node: {
        extensions: ['.js', '.jsx', '.json', '.ts', '.tsx', '.d.ts'], // add Typescript and CoffeeScript extensions
      },
    },
    react: {
      version: 'detect',
    },
  },
  overrides: [
    {
      files: require('./jest.config').testMatch,
      plugins: ['jest'],
      env: {
        'jest/globals': true,
      },
      rules: {
        'jest/prefer-to-be-null': 'error',
        'jest/prefer-to-be-undefined': 'error',
        'jest/prefer-to-contain': 'error',
        'jest/no-test-return-statement': 'error',
        'jest/no-large-snapshots': 'warn',
      },
    },
    {
      files: ['ui/**/*', 'spec/**/*', 'public/**/*', 'packages/**/*'],
      rules: {
        // Turn off the "absolute-first" rule. Until we get rid of the `compiled/` and `jsx/`
        // stuff and use real realitive paths it will tell you to do the wrong thing
        'import/first': ['error', 'disable-absolute-first'],

        'import/no-amd': 'error',
        'import/no-commonjs': 'warn',
        'import/no-extraneous-dependencies': 'off', // allows 'i18n!webzip_exports' and 'compiled/foo/bar'
        'import/no-nodejs-modules': 'error',
        'import/order': 'off', // because it thinks 'jsx/whatever' and 'compiled/baz' should go in their groups. we don't want to encourage people to do that just so they move them back together once  those everything is in same dir
        'import/no-unresolved': 'off',
        'import/no-webpack-loader-syntax': 'off',
        'import/newline-after-import': 'warn',

        'jest/no-jasmine-globals': 'error',
        'no-constant-condition': 'error',
        'react-hooks/exhaustive-deps': 'error',
        'react/prefer-stateless-function': 'error',
        'prefer-const': 'warn',

        // TODO: resolve and remove these overrides
        'react/no-string-refs': 'warn',
        'react/no-this-in-sfc': 'warn',
        'react/prop-types': 'warn',
        'react/no-access-state-in-setstate': 'warn',
        'react/no-find-dom-node': 'warn',
        'react/no-unused-prop-types': 'warn',
      },
    },
    {
      files: ['jest/**/*'],
      rules: {
        'import/extensions': 'off',
        'import/no-commonjs': 'off',
        'import/no-extraneous-dependencies': 'off',
        'import/order': 'off',
      },
    },
    {
      files: [
        'ui/features/quiz_log_auditing/**/*',
        'ui/features/quiz_statistics/**/*',
        'ui/shared/quiz-legacy-client-apps/**/*',
        'ui/shared/quiz-log-auditing/**/*',
      ],
      rules: {
        'react/prop-types': 'off',
        'react/no-string-refs': 'warn',
      },
    },
  ],
}
