var distes6 = require('broccoli-dist-es6-module');
module.exports = distes6('lib', {
  global: 'ic.ajax',
  packageName: 'ic-ajax',
  main: 'main',
  shim: {
    'ember': 'Ember'
  }
});
