define(function(require) {
  var React = require('react');
  var ActorMixin = require('../mixins/components/actor');

  if (!React.addons) {
    React.addons = {};
  }

  React.addons.ActorMixin = ActorMixin;

  return React;
});