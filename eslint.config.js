const globals = require('globals')
const pluginJs = require('@eslint/js')
const tseslint = require('typescript-eslint')
const pluginReact = require('eslint-plugin-react')
const jsxA11y = require('eslint-plugin-jsx-a11y')
const pluginReactHooks = require('eslint-plugin-react-hooks')
const pluginPromise = require('eslint-plugin-promise')
const importPlugin = require('eslint-plugin-import')
const lodashPlugin = require('eslint-plugin-lodash')
const notice = require('eslint-plugin-notice')
const comments = require('@eslint-community/eslint-plugin-eslint-comments/configs')

/** @type {import('eslint').Linter.Config[]} */
module.exports = [
  {
    files: ['ui/**/*.{js,mjs,ts,jsx,tsx}', 'ui-build/**/*.{js,mjs,ts,jsx,tsx}'],
    ignores: ['**/doc/*', '**/es/*', 'Jenkinsfile.js', 'ui/shared/jquery/**', '*.config.*'],
  },

  // Globals
  {
    languageOptions: {
      globals: {
        ...globals.browser,
        ...globals.node,
        ENV: true,
        JSX: true,
        INST: true,
        tinyMCE: true,
        tinymce: true,
        structuredClone: true,
      },
    },
  },

  // JavaScript
  pluginJs.configs.recommended,
  {
    rules: {
      'no-constant-binary-expression': 'warn',
      'no-dupe-class-members': 'warn',
      'no-import-assign': 'warn',
      'no-loss-of-precision': 'warn',
      'no-prototype-builtins': 'off',
      'no-unexpected-multiline': 'warn',
      'no-unsafe-optional-chaining': 'warn',
      'no-unused-expressions': 'off',
      'no-useless-escape': 'warn',
      'prefer-const': 'warn',
      'prefer-rest-params': 'off',
      'react/no-unknown-property': 'warn',
      'no-redeclare': 'warn',
      'no-global-assign': 'warn',
    },
  },

  // TypeScript
  ...tseslint.configs.recommended,
  {
    rules: {
      '@typescript-eslint/ban-ts-comment': 'off',
      '@typescript-eslint/no-unused-vars': [
        'warn',
        {
          args: 'all',
          argsIgnorePattern: '^_',
          caughtErrors: 'all',
          caughtErrorsIgnorePattern: '^_',
          destructuredArrayIgnorePattern: '^_',
          varsIgnorePattern: '^_',
          ignoreRestSiblings: true,
        },
      ],
      '@typescript-eslint/no-this-alias': 'off',
      '@typescript-eslint/no-explicit-any': 'off',
      '@typescript-eslint/no-unused-expressions': 'warn',
      '@typescript-eslint/no-empty-object-type': 'warn',
      '@typescript-eslint/no-unsafe-function-type': 'warn',
      '@typescript-eslint/no-require-imports': 'off',
      '@typescript-eslint/no-wrapper-object-types': 'warn',
      '@typescript-eslint/no-non-null-asserted-optional-chain': 'warn',
      'prefer-rest-params': 'off',
      'prefer-const': 'warn',
      'no-unused-private-class-members': 'warn',
    },
    languageOptions: {
      globals: globals.typescript,
    },
  },

  // Copyright / Open Source Header
  {
    files: ['ui/**/*.{js,mjs,ts,jsx,tsx}', 'ui-build/**/*.{js,mjs,ts,jsx,tsx}'],
    // ignore config files
    ignores: ['**/*.config.js'],
    plugins: {
      notice,
    },
    rules: {
      // Lenient so we don't automatically put our copyright notice on
      //   top of something already copyrighted by someone else.
      'notice/notice': [
        'error',
        {
          templateFile: 'config/copyright-template.js',
          mustMatch: 'Copyright ',
        },
      ],
    },
  },

  // Lodash
  {
    plugins: {lodash: lodashPlugin},
    rules: {
      'lodash/callback-binding': 'error',
      'lodash/collection-method-value': 'error',
      'lodash/collection-return': 'error',
      'lodash/no-extra-args': 'error',
      'lodash/no-unbound-this': 'error',
    },
  },

  // Promises
  pluginPromise.configs['flat/recommended'],
  {
    rules: {
      'promise/always-return': 'off',
      'promise/catch-or-return': 'off',
    },
  },

  // Imports
  importPlugin.flatConfigs.recommended,
  {
    files: [
      'ui/**/*.{js,mjs,ts,jsx,tsx}',
      'ui-build/**/*.{js,mjs,ts,jsx,tsx}',
      'packages/**/*.{js,mjs,ts,jsx,tsx}',
    ],
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'commonjs',
    },
    rules: {
      'no-unused-vars': 'off',
      'import/no-dynamic-require': 'warn',
      'import/no-nodejs-modules': 'warn',
      'import/no-unresolved': 'off',
      'import/named': 'off',
      'import/namespace': 'off',
    },
  },

  // React
  pluginReact.configs.flat.recommended,
  {
    plugins: {react: pluginReact},
    settings: {
      react: {
        version: 'detect',
      },
    },
    rules: {
      'react/no-deprecated': 'warn',
      'react/prop-types': 'warn',
      'react/display-name': 'off',
      'react/jsx-key': 'warn',
      'react/no-string-refs': 'warn',
      'react/no-find-dom-node': 'warn',
      'react/no-unknown-property': 'warn',
      'react/jsx-no-target-blank': 'warn',
    },
  },

  // React Hooks
  {
    plugins: {'react-hooks': pluginReactHooks},
    rules: {
      'react-hooks/rules-of-hooks': 'off', // until useI18nScope is renamed
      'react-hooks/exhaustive-deps': 'warn',
    },
  },

  // JSX A11y
  jsxA11y.flatConfigs.recommended,
  {
    rules: {
      'jsx-a11y/no-interactive-element-to-noninteractive-role': 'warn',
      '@eslint-community/eslint-comments/no-duplicate-disable': 'warn',
      'jsx-a11y/role-has-required-aria-props': 'warn',
      'jsx-a11y/no-autofocus': 'warn',
    },
  },

  // Extra ESLint Comment rules
  comments.recommended,
  {
    rules: {
      '@eslint-community/eslint-comments/disable-enable-pair': ['error', {allowWholeFile: true}],
    },
  },

  // Testcafe
  {
    files: ['**/testcafe/**/*.{js,mjs,ts,jsx,tsx}'],
    languageOptions: {
      globals: {
        test: true,
        fixture: true,
      },
    },
  },

  // Jest
  require('./eslint.config.jest'),

  // QUnit
  require('./eslint.config.qunit'),
]
