define({
  load: function(name, req, load, config) {
    req(['bower/fullcalendar/dist/fullcalendar'], function() {
      req(['bower/fullcalendar/dist/lang-all'], load);
    });
  }
});
