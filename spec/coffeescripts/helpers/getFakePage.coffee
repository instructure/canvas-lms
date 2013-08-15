define ->

  # helper to get a fake page from the "server", gives you some fake model data
  # and the Link header, don't send it a page greater than 10 or less than 1
  getFakePage = (thisPage = 1) ->
    url = (page) -> "/api/v1/context/2/resource?page=#{page}&per_page=2"
    lastID = thisPage * 2
    urls =
      current: url thisPage
      first: url 1
      last: url 10
    links = ['<' + urls.current + '>; rel="current"']
    if thisPage < 10
      urls.next = url thisPage + 1
      links.push '<' + urls.next + '>; rel="next"'
    if thisPage > 1
      urls.prev = url thisPage - 1
      links.push '<' + urls.prev + '>; rel="prev"'
    links.push '<' + urls.first + '>; rel="first"'
    links.push '<' + urls.last + '>; rel="last"'

    urls: urls
    header: links.join ','
    data: [
      id: lastID - 1, foo: 'bar', baz: 'qux'
    ,
      id: lastID, foo: 'bar', baz: 'qux'
    ]


