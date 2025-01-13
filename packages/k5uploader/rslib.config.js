/** @type {import('@rslib/core').RslibConfig} */
export default {
  lib: [
    {
      entry: {
        index: 'src/index.ts',
      },
      format: 'esm',
      syntax: 'es2021',
    },
    {
      entry: {
        index: 'src/index.ts',
      },
      format: 'cjs',
      syntax: 'es2021',
    },
  ],
  output: {
    target: 'web',
    minify: {
      jsOptions: {
        minimizerOptions: {
          mangle: false,
          minify: false,
          compress: false,
        },
      },
    },
  },
}
