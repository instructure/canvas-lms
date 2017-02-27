define [
  'jsx/shared/helpers/parseLinkHeader'
], (parseLinkHeader) ->

  QUnit.module 'parseLinkHeader',
    setup: ->
      @axiosResponse =
        data: {}
        headers:
          link: '<http://canvas.example.com/api/v1/someendpoint&page=1&per_page=50>; rel="current",' +
                '<http://canvas.example.com/api/v1/someendpoint&page=1&per_page=50>; rel="first",' +
                '<http://canvas.example.com/api/v1/someendpoint&page=2&per_page=50>; rel="next",' +
                '<http://canvas.example.com/api/v1/someendpoint&page=3&per_page=50>; rel="last"'

  test 'it pulls out the links from an Axios response header', ->
    links = parseLinkHeader(@axiosResponse)
    expected =
      current: 'http://canvas.example.com/api/v1/someendpoint&page=1&per_page=50'
      first: 'http://canvas.example.com/api/v1/someendpoint&page=1&per_page=50'
      next: 'http://canvas.example.com/api/v1/someendpoint&page=2&per_page=50'
      last: 'http://canvas.example.com/api/v1/someendpoint&page=3&per_page=50'

    deepEqual links, expected, 'the links matched'