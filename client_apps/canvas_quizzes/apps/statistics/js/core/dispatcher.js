define(function(require) {
  var CoreDispatcher = require('canvas_quizzes/core/dispatcher');
  var config = require("../config");

  singleton = new CoreDispatcher(config);
  return singleton;
});
