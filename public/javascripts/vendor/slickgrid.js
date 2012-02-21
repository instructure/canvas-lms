/* just require all the "vanilla" js and return the object they define */
define([
  'jquery',
  'order!vendor/slickgrid/lib/jquery.event.drag-2.0.min',
  'order!vendor/slickgrid/slick.core',
  'order!vendor/slickgrid/slick.grid',
  'order!vendor/slickgrid/slick.editors',
  'order!vendor/slickgrid/plugins/slick.rowselectionmodel'
], function($) {
  return window.Slick;
});

