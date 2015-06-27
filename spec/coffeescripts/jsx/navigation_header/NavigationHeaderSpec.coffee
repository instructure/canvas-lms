define [
  'jquery'
  'react'
  'jsx/navigation_header/Navigation'
], ($, React, Navigation) ->

  wrapper = document.getElementById('fixtures')
  $(wrapper).append('<div id="holder">')
  componentHolder = document.getElementById('holder')

  renderComponent = ->
    React.render(Navigation(), componentHolder)

  module 'GlobalNavigation',
    setup: ->
      # Need to setup the global nav stuff we are testing
      @$inbox_data = $('<a id="global_nav_conversations_link" href="/conversations" class="ic-app-header__menu-list-link">' +
                      '<div class="menu-item-icon-container"><span class="menu-item__badge" style="display: none">0</span>' +
                      '</div></a>')
      $(wrapper).append(@$inbox_data)
      @server = sinon.fakeServer.create()
      window.ENV.current_user_id = 10
      response =
        unread_count: 10
      @server.respondWith("GET", /unread/, [200, { "Content-Type": "application/json" }, JSON.stringify(response)])
      @component = renderComponent()

    teardown: ->
      @server.restore()
      React.unmountComponentAtNode componentHolder
      $('#holder').remove()
      @$inbox_data.remove()

  test 'it renders', ->
    ok @component.isMounted()

  test 'shows the inbox badge when necessary', ->
    @server.respond()
    $badge = $('#global_nav_conversations_link').find('.menu-item__badge')
    ok $badge.is(':visible')
