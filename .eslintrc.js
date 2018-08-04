module.exports = {
  env: {
    es6: true,
    amd: true,
    browser: true,
    "jest/globals": true
  },
  extends: [
    "airbnb",
    "prettier",
    "prettier/react",
    "plugin:jest/recommended",
    "plugin:jsx-a11y/recommended"
  ],
  parserOptions: {
    ecmaVersion: 7,
    ecmaFeatures: {
      experimentalObjectRestSpread: true,
      jsx: true
    },
    sourceType: "module"
  },
  parser: "babel-eslint",

  globals: {
    ENV: true,
    INST: true,
  },
  plugins: [
    "promise",
    "import",
    "notice",
    "jest",
    "prettier"
  ],
  // 0 - off, 1 - warning, 2 - error
  rules: {
    "camelcase": [0], // because we have a ton of `const $user_name = $('#user_name')`
    "class-methods-use-this": [0],
    "comma-dangle": [2, "only-multiline"],
    "func-names": [0],
    "max-len": [1, {"code": 140}],
    "no-continue": [0],
    "react/no-typos": [0],
    "no-cond-assign": ["warn", "except-parens"],
    "no-else-return": [0],
    "no-nested-ternary": "off",
    "no-plusplus": [0],
    "no-return-assign": "off",
    "no-underscore-dangle": [0],
    "no-unused-vars": [2, { "argsIgnorePattern": "^_"}],
    "no-use-before-define": "off",
    "one-var": ["error", { initialized: "never" }], // allow `let foo, bar` but not `let foo=1, bar=2`
    "object-curly-spacing": [0],
    "prefer-destructuring": "off",
    "padded-blocks": [0], // so we can have space between the define([... and the callback
    "semi": [0],
    "import/named": [2],
    "import/no-extraneous-dependencies": ["error", {"devDependencies": true}],
    "import/no-commonjs": "off",
    "jest/prefer-to-be-null": "error",
    "jest/prefer-to-be-undefined": "error",
    "react/jsx-filename-extension": [2, { "extensions": [".js"] }],
    "import/extensions": [1, { "js": "never", "jsx": "never", "json": "always" }],
    'notice/notice': ['error', {
      templateFile: 'config/copyright-template.js',
      // purposely lenient so we don't automatically put our copyright notice on
      // top of something already copyrighted by someone else.
      mustMatch: 'Copyright '
    }],
    "promise/avoid-new": [0],
  },
  overrides: [
    {
      files: ['app/**/*', 'spec/**/*', 'public/**/*'],
      rules: {
        // Turn off the "absolute-first" rule. Until we get rid of the `compiled/` and `jsx/`
        // stuff and use real realitive paths it will tell you to do the wrong thing
        "import/first": ["error", {"absolute-first": false}],

        "import/no-amd": "error",
        "import/no-commonjs": "error",
        "import/no-extraneous-dependencies": "off", // allows 'i18n!webzip_exports' and 'compiled/foo/bar'
        "import/no-nodejs-modules": "error",
        "import/no-unresolved": "off",
        "import/no-webpack-loader-syntax": "off"
      },
    },
    {
      // If you are starting a new project or section of greenfield code,
      // or if there is a folder of code that your team controls that you want
      // to start ensuring conforms to prettier, add it to this array to opt-in
      // now to conform to prettier.
      files: [
        'app/jsx/permissions/**/*.js'
      ],
      rules: {
        'prettier/prettier': 'error'
      }
    }
  ]
}

