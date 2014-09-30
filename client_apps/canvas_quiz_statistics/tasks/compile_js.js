module.exports = {
  description: 'Build an optimized version of the JavaScript sources.',
  runner: [
    'clean:compiled_symlink',
    'clean:compiled_jsx',
    'copy:src',
    'copy:map',
    'convert_jsx_i18n',
    'react:build',
    'symlink:compiled',
    'shim_canvas_packages',
    'requirejs',
    'clean:compiled_symlink',
    'clean:compiled_jsx',
  ]
};