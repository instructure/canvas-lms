define(function(require) {
  var floor = Math.floor;

  var pad = function(duration) {
    return ('00' + duration).slice(-2);
  };

  /**
   * @member Util
   *
   * Format a duration given in seconds into a stopwatch-style timer, e.g:
   *
   * - 1 second      => `00:01`
   * - 30 seconds    => `00:30`
   * - 84 seconds    => `01:24`
   * - 7230 seconds  => `02:00:30`
   * - 7530 seconds  => `02:05:30`
   *
   * @param {Number} seconds
   *        The duration in seconds.
   *
   * @return {String}
   */
  var secondsToTime = function(seconds) {
    var hh, mm, ss;

    if (seconds > 3600) {
      hh = floor(seconds / 3600);
      mm = floor((seconds - hh*3600) / 60);
      ss = seconds % 60;
      return [ hh, mm, ss ].map(pad).join(':');
    }
    else {
      return [ seconds / 60, seconds % 60 ].map(floor).map(pad).join(':');
    }
  };

  return secondsToTime;
});