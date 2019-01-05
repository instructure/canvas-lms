module.exports = {
  env: {
    es6: true,
    amd: true,
    browser: true
  },
  extends: [
    'airbnb',
    'prettier/react',
    'plugin:jest/recommended',
    'plugin:prettier/recommended',
    'plugin:eslint-comments/recommended',
    'plugin:promise/recommended'
  ],
  parserOptions: {
    ecmaVersion: 2018,
    ecmaFeatures: {
      jsx: true
    },
    sourceType: 'module'
  },
  parser: 'babel-eslint',

  globals: {
    ENV: true,
    INST: true,
    tinyMCE: true,
    tinymce: true
  },
  plugins: ['promise', 'import', 'notice', 'jest', 'prettier', 'jsx-a11y', 'lodash', 'react'],
  rules: {
    // These deal with prettier and will eventually be removed
    'prettier/prettier': 'off',
    'no-cond-assign': ['error', 'except-parens'],

    // These come from our extended configurations, but we don't care about them
    camelcase: 'off', // because we have a ton of `const $user_name = $('#user_name')`
    'class-methods-use-this': 'off',
    'consistent-return': 'off',
    'default-case': 'off',
    eqeqeq: 'warn', // great goal! but since we do it 1061 times, downgrade AirBnB's 'error' to 'warn' :(
    'func-names': 'off',
    'global-require': 'off', // every time we did this, we meant to
    'guard-for-in': 'off',
    'no-continue': 'off',
    'no-else-return': 'off',
    'no-multi-assign': 'off',
    'no-nested-ternary': 'off',
    'no-new': 'off', // because we do `new SomeView()` all the time in Backbone just for the sideffects
    'no-param-reassign': 'off',
    'no-plusplus': 'off',
    'no-prototype-builtins': 'off',
    'no-return-assign': 'off',
    'no-shadow': 'warn', // AirBnB says 'error', we downgrade to just 'warn'
    'no-underscore-dangle': 'off',
    'no-use-before-define': 'off',
    'no-useless-escape': 'off',
    'one-var': 'off',
    'prefer-destructuring': 'off',
    'prefer-rest-params': 'off',
    'eslint-comments/disable-enable-pair': ['error', {allowWholeFile: true}], // We are okay with turning rules off for the entirety of a file (though use it sparingly)
    'import/prefer-default-export': 'off',
    'jsx-a11y/label-has-for': 'off',
    'jsx-a11y/anchor-is-valid': ['error', {components: []}], // InstUI has special behavior around this
    'promise/always-return': 'off',
    'promise/catch-or-return': 'warn', // The recommendation is to error on this, but we downgrade it to a warning
    'promise/avoid-new': 'off',
    'promise/no-nesting': 'off',
    'react/destructuring-assignment': 'off',
    'react/no-typos': 'off',
    'react/sort-comp': 'off',
    'react/require-default-props': 'off',
    'react/default-props-match-prop-types': ['error', {allowRequiredDefaults: true}], // add the `allowRequiredDefaults: true` option to allow specifying something as a required prop (so you get propType error messages), but in case it's not present at runtime, I'll use `[]` as the default (so it is resilient)".
    'react/forbid-foreign-prop-types': 'off', // You can refer to proptypes within proptypes, but you shouldn't use proptypes in actual app code of the component
    'react/no-danger': 'off', // dangerouslySetInnerHTML is already pretty explicit on making you aware of its danger
    'react/no-render-return-value': 'warn', // In future versions of react this will fail
    'no-restricted-syntax': [
      // This is here because we are turning off 2 items from what AirBnB cares about.
      'error',
      {
        selector: 'LabeledStatement',
        message:
          'Labels are a form of GOTO; using them makes code confusing and hard to maintain and understand.'
      },
      {
        selector: 'WithStatement',
        message:
          '`with` is disallowed in strict mode because it makes code impossible to predict and optimize.'
      }
    ],

    // These are discouraged, but allowed
    'no-console': 'warn',
    'jest/no-large-snapshots': 'warn',

    // These are things we care about
    'react/jsx-filename-extension': ['error', {extensions: ['.js']}],
    'no-unused-vars': ['error', {argsIgnorePattern: '^_'}],
    'eslint-comments/no-unused-disable': 'error',
    'import/extensions': ['error', 'ignorePackages', {js: 'never'}],
    'import/no-commonjs': 'off', // This is overridden where it counts
    'import/no-extraneous-dependencies': ['error', {devDependencies: true}],
    'lodash/callback-binding': 'error',
    'lodash/collection-method-value': 'error',
    'lodash/collection-return': 'error',
    'lodash/no-extra-args': 'error',
    'lodash/no-unbound-this': 'error',
    'notice/notice': [
      'error',
      {
        templateFile: 'config/copyright-template.js',
        // purposely lenient so we don't automatically put our copyright notice on
        // top of something already copyrighted by someone else.
        mustMatch: 'Copyright '
      }
    ]
  },
  settings: {
    react: {
      version: '16'
    }
  },
  overrides: [
    {
      files: require('./jest.config').testMatch,
      plugins: ['jest'],
      env: {
        'jest/globals': true
      },
      rules: {
        'jest/prefer-to-be-null': 'error',
        'jest/prefer-to-be-undefined': 'error',
        'jest/prefer-to-contain': 'error',
        'jest/no-test-return-statement': 'error',
        'jest/no-large-snapshots': 'warn'
      }
    },
    {
      files: ['app/**/*', 'spec/**/*', 'public/**/*'],
      rules: {
        // Turn off the "absolute-first" rule. Until we get rid of the `compiled/` and `jsx/`
        // stuff and use real realitive paths it will tell you to do the wrong thing
        'import/first': ['error', {'absolute-first': false}],

        'import/no-amd': 'error',
        'import/no-commonjs': 'warn',
        'import/no-extraneous-dependencies': 'off', // allows 'i18n!webzip_exports' and 'compiled/foo/bar'
        'import/no-nodejs-modules': 'error',
        'import/order': 'off', // because it thinks 'jsx/whatever' and 'compiled/baz' should go in their groups. we don't want to encourage people to do that just so they move them back together once  those everything is in same dir
        'import/no-unresolved': 'off',
        'import/no-webpack-loader-syntax': 'off'
      }
    },
    {
      files: require('./.prettierwhitelist'),
      rules: {
        'prettier/prettier': 'error'
      }
    }
  ]
}
