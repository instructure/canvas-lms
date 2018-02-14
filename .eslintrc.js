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
    "jest"
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
    "no-else-return": [0],
    "no-plusplus": [0],
    "no-return-assign": ['error', 'except-parens'],
    "no-underscore-dangle": [0],
    "no-unused-vars": [2, { "argsIgnorePattern": "^_"}],
    "one-var": ["error", { initialized: "never" }], // allow `let foo, bar` but not `let foo=1, bar=2`
    "object-curly-spacing": [0],
    "prefer-destructuring": [
      "error",
      {
        VariableDeclarator: {
          array: true, // allow `let [bar] = foo`; reject `let bar = foo[0]`
          object: true // allow `let { bar: foo } = object`; reject `let foo = object.bar`
        },
        AssignmentExpression: {
          array: false, // allow `let bar; bar = foo[0]`; this matters for conditional assignment
          object: false // allow `let bar; bar = foo.bar`; this matters for conditional assignment
        }
      }
    ],
    "padded-blocks": [0], // so we can have space between the define([... and the callback
    "semi": [0],
    "import/no-extraneous-dependencies": [0], // allows 'i18n!webzip_exports' and 'compiled/foo/bar'
    "import/named": [2],
    "import/no-unresolved": [0],
    "import/no-webpack-loader-syntax": [0],
    "import/no-commonjs": [2],
    "jest/prefer-to-be-null": "error",
    "jest/prefer-to-be-undefined": "error",
    "react/jsx-filename-extension": [2, { "extensions": [".js"] }],
    "import/extensions": [1, { "js": "never", "jsx": "never", "json": "always" }],
    "promise/avoid-new": [0],
  }
}

