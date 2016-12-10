define([
], function () {
  var Helper = {}

  Helper.setWindowLocation = function (url) {
    window.location = url
  }

  Helper.externalUrlLinkClick = function (event, $elt) {
    event.preventDefault()
    this.setWindowLocation($elt.attr('data-item-href'))
  }.bind(Helper)

  return Helper
})
