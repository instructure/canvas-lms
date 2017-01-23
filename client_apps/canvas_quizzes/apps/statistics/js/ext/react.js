define((require) => {
  const React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  const ActorMixin = require('../mixins/components/actor');

  if (!React.addons) {
    React.addons = {};
  }

  React.addons.ActorMixin = ActorMixin;

  return React;
});
