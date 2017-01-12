define([
  'react',
  './components/gradebook'
], function (React, Gradebook) {
  let MOUNT_ELEMENT = document.getElementById('gradebook_grid');
  React.render(<Gradebook/>, MOUNT_ELEMENT);
});

