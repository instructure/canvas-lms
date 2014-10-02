define(['bower/react-modal/dist/react-modal'], function(ReactModal) {
  var appElement = document.getElementById('application');

  // In general this will be present, but in the case that it's not present,
  // you'll need to set your own which most likely occurs during tests.

  if (appElement) {
    ReactModal.setAppElement(document.getElementById('application'));
  }

  return ReactModal;
});