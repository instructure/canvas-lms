define((require) => {
  const RSVP = require('./initializers/rsvp');
  const Backbone = require('./initializers/backbone');

  return function initializeApp () {
    return RSVP.resolve();
  };
});
