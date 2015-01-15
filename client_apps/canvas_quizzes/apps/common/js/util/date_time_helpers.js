define(function(require) {
  var $ = require('canvas_packages/jquery');
  var Void = require('canvas_packages/jquery/instructure_date_and_time');

  var exports = {};

  exports.friendlyDatetime = function(dateTime, perspective) {
    var muddledDateTime = dateTime;

    if (muddledDateTime) {
      muddledDateTime.clone = function() {
        return new Date(muddledDateTime.getTime());
      };
    }

    return $.friendlyDatetime(muddledDateTime, perspective);
  };

  exports.fudgeDateForProfileTimezone = $.fudgeDateForProfileTimezone;

  return exports;
});