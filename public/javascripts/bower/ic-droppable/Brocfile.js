module.exports = require('broccoli-dist-es6-module')('lib', {
  global: 'ic.Droppable',
  packageName: 'ic-droppable',
  main: 'main',
  shim: {
    'ember': 'Ember'
  }
});

