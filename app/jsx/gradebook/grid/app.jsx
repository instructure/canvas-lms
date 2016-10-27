define([
  'react-dom',
  './components/gradebook'
], function (ReactDOM, Gradebook) {
  let MOUNT_ELEMENT = document.getElementById('gradebook_grid');
  ReactDOM.render(<Gradebook/>, MOUNT_ELEMENT);
});

