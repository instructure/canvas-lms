define [
  'jquery'
  'compiled/PaginatedList'
], ($, PaginatedList) ->
  paginatedListFixture = """
    <h3>Paginated List Spec</h3>
    <div id="list-wrapper">
      <ul></ul>
    </div>
    """

  module 'PaginatedList',

    setup: ->
      # server response
      @response = [200, { 'Content-Type': 'application/json' }, '[{ "value": "one" }, { "value": "two" }]']
      # fake template (mimics a handlebars function)
      @template = (opts) ->
        tpl = (opt) ->
          "<li>#{opt['value']}</li>"
        (tpl(opt) for opt in opts).join ''
      @fixture = $(paginatedListFixture).appendTo('#fixtures')
      @el =
        wrapper: $('#list-wrapper')
        list: $('#list-wrapper').find('ul')
      @clock  = sinon.useFakeTimers()
      @server = sinon.fakeServer.create()
    teardown: ->
      @clock.restore()
      @server.restore()
      @fixture.remove()

  test 'should fetch and display results', ->
    @server.respondWith(/.+/, @response)

    new PaginatedList @el.wrapper,
      template: @template
      url: '/api/v1/test.json'
    @server.respond()
    @clock.tick 500

    equal @el.list.children().length, 2

  test 'should display a view more link if next page is available', ->
    @server.respondWith(/.+/, [@response[0], { 'Content-Type': 'application/json', 'Link': 'rel="next"' }, @response[2]])

    new PaginatedList @el.wrapper,
      template: @template
      url: '/api/v1/test.json'
    @server.respond()
    @clock.tick 500

    ok @el.wrapper.find('.view-more-link').length > 0

  test 'should not display a view more link if there is no next page', ->
    @server.respondWith(/.+/, @response)

    new PaginatedList @el.wrapper,
      template: @template
      url: '/api/v1/test.json'
    @server.respond()
    @clock.tick 500

    ok @el.wrapper.find('.view-more-link').length is 0

  test 'should accept a template function', ->
    @server.respondWith(/.+/, @response)

    new PaginatedList @el.wrapper,
      template: @template
      url: '/api/v1/test.json'
    @server.respond()
    @clock.tick 500

    equal @el.list.find('li:first-child').text(), 'one'
    equal @el.list.find('li:last-child').text(), 'two'

  test 'should accept a presenter function', ->
    @server.respondWith(/.+/, @response)

    new PaginatedList @el.wrapper,
      presenter: (list) ->
        ({ value: 'changed' } for l in list)
      template: @template
      url: '/api/v1/test.json'
    @server.respond()
    @clock.tick 500

    equal @el.list.find('li:first-child').text(), 'changed'

  test 'should allow user to defer getJSON', ->
    @spy($, 'getJSON')
    new PaginatedList @el.wrapper,
      start: false
      template: @template,
      url: '/api/v1/not-called.json'

    equal $.getJSON.callCount, 0
