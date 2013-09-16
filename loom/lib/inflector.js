var fleck = require('fleck');

module.exports = fleck;

/*
 * CapitalizedCamelCase
 */

fleck.classify = function(str) {
  return fleck.camelize(str, true);
};

/*
 * users/update_avatar -> UsersUpdateAvatar
 */

fleck.objectify /*lol*/ = function (str) { 
  str = str.replace(/\//g, '_');
  return fleck.classify(str);
};

fleck.humanize = function(str) {
  return fleck.capitalize(fleck.underscore(str).replace(/_/g, ' '));
};

