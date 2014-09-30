// Rename all files to end with .js; source can be .jsx, or .hm.jsx
var rename = function (dest, src) {
  var folder    = src.substring(0, src.lastIndexOf('/'));
  var filename  = src.substring(src.lastIndexOf('/'), src.length);
  var extIndex = filename.lastIndexOf('.');
  var extension;

  extension = filename.substring(extIndex+1, filename.length);
  filename  = filename.substring(0, extIndex);

  return dest +'/' + folder + filename + '.' + extension.replace(/jsx/, 'js');
};

module.exports = {
  dev: {
    files: [{
      expand: true,
      cwd: 'src/js',
      src: [ '**/*.jsx' ],
      dest: 'tmp/compiled/jsx',
      rename: rename
    }]
  },

  build: {
    options: {
      // ignoreMTime: true
    },

    files: [{
      expand: true,
      cwd: 'tmp/js/canvas_quiz_statistics',
      src: [ '**/*.jsx' ],
      dest: 'tmp/compiled/jsx',
      rename: rename
    }]
  }
};