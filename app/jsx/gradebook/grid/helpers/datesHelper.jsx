define([
  'underscore',
  'timezone'
], function (_, tz) {
  var DatesHelper = {
    parseDates: function(object, datesToParse) {
      _.each(datesToParse, (dateString) => {
        var propertyExists = !_.isUndefined(object[dateString]);
        if (propertyExists) object[dateString] = tz.parse(object[dateString]);
      });
      return object;
    }
  };
  return DatesHelper;
});