/** @jsx React.DOM */

define([
  'react',
  './components/gradebook'
], function (React, Gradebook) {
  var MOUNT_ELEMENT = document.getElementById('gradebook_grid');

  React.render(<Gradebook/>, MOUNT_ELEMENT);
});

