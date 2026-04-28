const globals = require('globals')
const tsParser = require('@typescript-eslint/parser')
const jsxA11y = require('eslint-plugin-jsx-a11y')
const notice = require('eslint-plugin-notice')
const comments = require('@eslint-community/eslint-plugin-eslint-comments/configs')
const pluginJest = require('eslint-plugin-jest')

/** @type {import('eslint').Linter.Config[]} */
module.exports = [
  {
    files: ['src/**/*.ts', 'src/**/*.tsx', 'src/**/*.js', 'src/**/*.jsx'],
  },
  {
    ignores: ['es/**/*', './src/translations/*/*', 'scripts', 'webpack.*.config.js'],
  },

  // Globals (needed for ESLint to resolve references in remaining rules)
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

  // TypeScript parser (needed to parse .ts/.tsx files)
  {
    files: ['**/*.{ts,tsx}'],
    languageOptions: {
      parser: tsParser,
    },
  },

  // Copyright / Open Source Header — not in oxlint
  {
    files: ['src/**/*.{js,mjs,ts,jsx,tsx}'],
    ignores: ['**/*.config.js', 'es/**/*', 'src/translations/**/*'],
    plugins: {notice},
    rules: {
      'notice/notice': [
        'error',
        {
          templateFile: '../../config/copyright-template.js',
          mustMatch: 'Copyright ',
        },
      ],
    },
  },

  // JSX A11y — only the rule pending in oxlint
  {
    plugins: {'jsx-a11y': jsxA11y},
    rules: {
      'jsx-a11y/no-interactive-element-to-noninteractive-role': 'warn',
    },
  },

  // ESLint Comments — not in oxlint
  comments.recommended,
  {
    rules: {
      '@eslint-community/eslint-comments/disable-enable-pair': ['error', {allowWholeFile: true}],
      '@eslint-community/eslint-comments/no-duplicate-disable': 'warn',
    },
  },

  // Jest — only rules not in oxlint
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
      // jest/no-disabled-tests, jest/no-focused-tests, jest/valid-expect → oxlint
      'jest/no-identical-title': 'warn',
      'jest/prefer-to-have-length': 'warn',
    },
  },
]
