define([
], () =>  {
  return function (linkHeader) {
    if (!linkHeader) {
      return []
    }
    var retVal = {}
    linkHeader.split(',').map((partOfHeader) => partOfHeader.split('; '))
    .forEach(function (link) {
      var myUrl = link[0].substring(1, link[0].length - 1)
      var urlRel = link[1].split('=')
      urlRel = urlRel[1]
      urlRel = urlRel.substring(1, urlRel.length - 1)

      retVal[urlRel] = myUrl
    })
    return retVal
  }
});
