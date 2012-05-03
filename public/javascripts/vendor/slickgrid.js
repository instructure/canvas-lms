// add any plugins to slickgrid here, make sure to add a
// shim for AMD compat in the require config
define([
  'use!vendor/slickgrid/slick.grid',
  'use!vendor/slickgrid/slick.editors',
  'use!vendor/slickgrid/plugins/slick.rowselectionmodel'
], function(Slick) {
  return Slick;
});

