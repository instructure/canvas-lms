define(function(require) {
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  var ActorMixin = require('../mixins/components/actor');

  if (!React.addons) {
    React.addons = {};
  }

  React.addons.ActorMixin = ActorMixin;

  return React;
});