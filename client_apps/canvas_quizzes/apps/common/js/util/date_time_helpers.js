define((require) => {
  const $ = require('canvas_packages/jquery');
  const Void = require('canvas_packages/jquery/instructure_date_and_time');

  const exports = {};

  exports.friendlyDatetime = function (dateTime, perspective) {
    const muddledDateTime = dateTime;

    if (muddledDateTime) {
      muddledDateTime.clone = function () {
        return new Date(muddledDateTime.getTime());
      };
    }

    return $.friendlyDatetime(muddledDateTime, perspective);
  };

  exports.fudgeDateForProfileTimezone = $.fudgeDateForProfileTimezone;

  return exports;
});
