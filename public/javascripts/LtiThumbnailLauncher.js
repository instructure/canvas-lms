define([
  'jquery' /* $ */
], function($) {

  var selector = ".lti-thumbnail-launch";

  function handleLaunch(event) {
    event.preventDefault();
    ltiThumbnailLauncher.launch($(event.target).closest(selector))
  }

  function LtiThumbnailLauncher() {
    $( document.body ).delegate( selector, 'click', handleLaunch );
  }

  LtiThumbnailLauncher.prototype.launch = function (element) {
    var placement = JSON.parse(element.attr('target')),
      iframe = $("<iframe/>", {
        src: element.attr('href'),
        width: placement.displayWidth || 500,
        height: placement.displayHeight || 500
      })
    element.replaceWith(iframe);
  };

  // There can be only one LtiThumbnailLauncher
  var ltiThumbnailLauncher = new LtiThumbnailLauncher(selector);
  return ltiThumbnailLauncher
});