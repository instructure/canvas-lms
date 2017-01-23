define((require) => {
  const CoreDispatcher = require('canvas_quizzes/core/dispatcher');
  const config = require('../config');

  singleton = new CoreDispatcher(config);
  return singleton;
});
