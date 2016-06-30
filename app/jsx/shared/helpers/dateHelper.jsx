define([
  'underscore',
  'jquery',
  'timezone',
  'jquery.instructure_date_and_time'
], function (_, $, tz) {
  var DateHelper = {
    parseDates: function(object, datesToParse) {
      _.each(datesToParse, (dateString) => {
        var propertyExists = !_.isUndefined(object[dateString]);
        if (propertyExists) object[dateString] = tz.parse(object[dateString]);
      });
      return object;
    },

    formatDatetimeForDisplay: function(date) {
      return $.datetimeString(date, { format: 'medium', timezone: ENV.CONTEXT_TIMEZONE });
    },

    formatDateForDisplay: function(date) {
      return $.dateString(date, { format: 'medium', timezone: ENV.CONTEXT_TIMEZONE });
    },

    isMidnight: function(date) {
      return tz.isMidnight(date, { timezone: ENV.CONTEXT_TIMEZONE });
    }
  };
  return DateHelper;
});
