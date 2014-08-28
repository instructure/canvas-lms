define([ 'rsvp' ], function(RSVP) {
  RSVP.on('error', function(e) {
    console.error('RSVP error:', e);

    if (e && e.message) {
      console.error(e.message);
    }
    if (e && e.stack) {
      console.error(e.stack);
    }
  });

  return RSVP;
});