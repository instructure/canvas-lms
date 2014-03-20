function parseLinkHeader(xhr) {
  var regex = /<(http.*?)>; rel="([a-z]*)",?/g;
  var links = {};
  var header = xhr.getResponseHeader('Link');
  if (!header) {
    header = xhr.getResponseHeader('link');
    if (!header) {
      return links;
    }
  }
  var link;
  while (link = regex.exec(header)) {
    links[link[2]] = link[1];
  }
  return links;
}

export default parseLinkHeader;

