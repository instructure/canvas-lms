var proxy = require('identity-obj-proxy');
var transform = require('@instructure/babel-plugin-themeable-styles/transform');
/*
  This is a babel transform to mock the themeable styles objects for the jest tests.
  See package.json for the jest config.
*/
module.exports = {
  process: function(src, filename) {
    return 'module.exports = ' + transform(proxy, src);
  }
};
