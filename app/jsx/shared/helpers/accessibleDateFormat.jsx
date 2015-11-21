/**
 * For use with date input fields.  Set the title to this value and
 * data-tooltip=""
 */

define(['i18n!dateformat'], function (I18n) {

  var accessibleDateFormat = () => {
    return I18n.t("YYYY-MM-DD hh:mm");
  };

  return accessibleDateFormat;

});
