/**
 * For use with date input fields.  Set the title to this value and
 * data-tooltip=""
 */

import I18n from 'i18n!dateformat'

var accessibleDateFormat = () => {
  return I18n.t("YYYY-MM-DD hh:mm");
};

export default accessibleDateFormat
