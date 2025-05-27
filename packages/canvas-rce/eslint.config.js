const globals = require('globals')
const pluginJs = require('@eslint/js')
const tseslint = require('typescript-eslint')
const pluginReact = require('eslint-plugin-react')
const jsxA11y = require('eslint-plugin-jsx-a11y')
const pluginReactHooks = require('eslint-plugin-react-hooks')
const pluginPromise = require('eslint-plugin-promise')
const importPlugin = require('eslint-plugin-import')
const notice = require('eslint-plugin-notice')
const comments = require('@eslint-community/eslint-plugin-eslint-comments/configs')
const pluginJest = require('eslint-plugin-jest')

/** @type {import('eslint').Linter.Config[]} */
module.exports = tseslint.config(
  // General
  {
    files: ['src/**/*.ts'],
  },
  {
    ignores: ['es/**/*', './src/translations/*/*', 'scripts', 'webpack.*.config.js'],
  },

  // Globals
  {
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'commonjs',
      globals: {
        ...globals.node,
        ...globals.browser,
        ENV: true,
        JSX: true,
        INST: true,
        tinyMCE: true,
        tinymce: true,
        structuredClone: true,
      },
    },
  },

  {
    rules: {
      'no-console': 'warn',
      'no-undef': 'warn',
      'no-unused-private-class-members': 'warn',
      'prefer-const': 'warn',
      'prefer-rest-params': 'off',
    },
  },

  // TypeScript
  ...tseslint.configs.recommended,
  {
    rules: {
      '@typescript-eslint/ban-ts-comment': 'off',
      '@typescript-eslint/no-empty-object-type': 'warn',
      '@typescript-eslint/no-explicit-any': 'off',
      '@typescript-eslint/no-non-null-asserted-optional-chain': 'warn',
      '@typescript-eslint/no-require-imports': 'off',
      '@typescript-eslint/no-this-alias': 'off',
      '@typescript-eslint/no-unsafe-function-type': 'warn',
      '@typescript-eslint/no-unused-expressions': 'warn',
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
      '@typescript-eslint/no-wrapper-object-types': 'warn',
      'no-undef': 'warn',
    },
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'commonjs',
      globals: {
        ...globals.typescript,
      },
    },
  },

  // JavaScript
  pluginJs.configs.recommended,
  {
    rules: {
      'no-constant-binary-expression': 'warn',
      'no-dupe-class-members': 'warn',
      'no-dupe-keys': 'warn',
      'no-import-assign': 'warn',
      'no-loss-of-precision': 'warn',
      'no-prototype-builtins': 'off',
      'no-redeclare': 'warn',
      'no-unexpected-multiline': 'warn',
      'no-unsafe-optional-chaining': 'warn',
      'no-unused-expressions': 'off',
      'no-unused-vars': 'off', // use @typescript-eslint/no-unused-vars instead
      'no-useless-escape': 'warn',
      'prefer-const': 'warn',
      'prefer-rest-params': 'off',
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

  // Copyright / Open Source Header
  {
    files: ['src/**/*.{js,mjs,ts,jsx,tsx}'],
    ignores: ['**/*.config.js', 'es/**/*', 'src/translations/**/*'],
    plugins: {
      notice,
    },
    rules: {
      // Lenient so we don't automatically put our copyright notice on
      //   top of something already copyrighted by someone else.
      'notice/notice': [
        'error',
        {
          templateFile: '../../config/copyright-template.js',
          mustMatch: 'Copyright ',
        },
      ],
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
    files: ['__tests__/**/*.{js,mjs,ts,jsx,tsx}', 'src/**/*.{js,mjs,ts,jsx,tsx}'],
    ignores: ['src/translations/**'],
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'commonjs',
    },
    rules: {
      'import/no-dynamic-require': 'warn',
      'import/no-nodejs-modules': 'warn',
      'import/no-unresolved': 'off', // not working properly
      'import/named': 'off',
      'import/namespace': 'off',
    },
  },

  // React Hooks
  {
    plugins: {'react-hooks': pluginReactHooks},
    rules: {
      'react-hooks/rules-of-hooks': 'warn',
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

  // Jest
  {
    files: [
      '__tests__/**/*.{js,mjs,ts,jsx,tsx}',
      'src/**/__tests__/**/*.{js,mjs,ts,jsx,tsx}',
      'src/rce/plugins/tinymce-a11y-checker/rules/__mocks__/index.js',
    ],
    ignores: ['es/**'],
    plugins: {jest: pluginJest},
    languageOptions: {
      globals: {
        ...pluginJest.environments.globals.globals,
        global: true,
      },
    },
    rules: {
      'jest/no-disabled-tests': 'warn',
      'jest/no-focused-tests': 'error',
      'jest/no-identical-title': 'warn',
      'jest/prefer-to-have-length': 'warn',
      'jest/valid-expect': 'error',
      'react/no-deprecated': 'warn',
    },
  },
)
