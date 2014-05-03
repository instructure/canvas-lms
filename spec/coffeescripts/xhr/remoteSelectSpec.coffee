define [
  'jquery'
  'underscore'
  'compiled/xhr/RemoteSelect'
], ($, _, RemoteSelect) ->
  module 'RemoteSelect',
    setup: ->
      @response = [200, { 'Content-Type': 'application/json' }, '[{ "label": "one", "value": 1 }, {"label": "two", "value": 2 }]']
      @el       = $('<select id="test-select"></select>').appendTo('body')

    teardown: ->
      @el.remove()

  test 'should load results into a select', ->
    server = @sandbox.useFakeServer()
    server.respondWith(/.+/, @response)

    rs = new RemoteSelect(@el, url: '/test/url.json')
    ok @el.prop('disabled')

    server.respond()
    equal @el.children().length, 2
    server.restore()

  test 'should load an object as <optgroup>', ->
    @response.pop()
    @response.push JSON.stringify {
      'Group One': [
        { label: 'One', value: 1 }
        { label: 'Two', value: 2 }
      ]
      'Group Two': [
        { label: 'Three', value: 3 }
        { label: 'Four', value: 4 }
      ]
    }

    server = @sandbox.useFakeServer()
    server.respondWith(/.+/, @response)

    rs = new RemoteSelect(@el, url: '/test/url.json')
    server.respond()
    equal @el.children('optgroup').length, 2
    equal @el.find('option').length, 4
    server.restore()

  test 'should cache responses', ->
    server = @sandbox.useFakeServer()
    server.respondWith(/.+/, @response)
    @spy($, 'getJSON')

    rs = new RemoteSelect(@el, url: '/test/cached.json')
    server.respond()

    ok $.getJSON.calledOnce
    equal _.keys(rs.cache.store).length, 1
    server.restore()

  test 'should accept a formatter', ->
    server = @sandbox.useFakeServer()
    @response.pop()
    @response.push JSON.stringify [
      { group: 'one', name: 'one', id: 1 }
      { group: 'one', name: 'two', id: 2 }
      { group: 'two', name: 'three', id: 3 }
      { group: 'two', name: 'four', id: 4 }
    ]
    server.respondWith(/.+/, @response)

    format = (data) ->
      groups = _.groupBy data, (obj) -> obj.group
      _.each groups, (group, key) ->
        groups[key] = _.map group, (item) ->
          label: item.name, value: item.id
      groups

    rs = new RemoteSelect(@el,
      formatter: format
      url: '/test/url.json')
    server.respond()

    equal @el.children('optgroup').length, 2
    equal @el.find('option').length, 4
    server.restore()

  test 'should take params', ->
    server = @sandbox.useFakeServer()
    @spy($, 'getJSON')

    rs = new RemoteSelect(@el,
      url: '/test/url.json',
      requestParams: { param: 'value' })

    ok $.getJSON.calledWith '/test/url.json', { param: 'value' }, rs.onResponse
    rs.spinner.remove()
    server.restore()

  test 'should include original options in select', ->
    server = @sandbox.useFakeServer()
    server.respondWith(/.+/, @response)
    @el.append '<option value="">Default</option>'

    rs = new RemoteSelect(@el, url: '/test/url.json')
    server.respond()

    equal @el.children().length, 3
    server.restore()
