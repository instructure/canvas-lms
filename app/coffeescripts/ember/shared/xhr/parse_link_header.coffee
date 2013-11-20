define ->

  regex = /<(http.*?)>; rel="([a-z]*)",/g

  parseLinkHeader = (jqXhr) ->
    links = {}
    header = jqXhr.getResponseHeader 'Link'
    return links unless header
    while link = regex.exec header
      links[link[2]] = link[1]
    links

