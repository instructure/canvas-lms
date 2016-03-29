/**
 * This is a version of app/coffeescripts/fn/parseLinkHeader.coffee
 * designed to work with axios instead of jQuery.
 *
 */

define([], function () {

  var regex = /<(http.*?)>; rel="([a-z]*)"/g;

  var parseLinkHeader = (axiosResponse) => {
    var links = {};
    var header = (axiosResponse.headers) ? axiosResponse.headers.link : null;
    if (!header) {
      return links;
    }
    var link = regex.exec(header);
    while (link) {
      links[link[2]] = link[1];
      link = regex.exec(header);
    }
    return links;
  };

  return parseLinkHeader;

});
