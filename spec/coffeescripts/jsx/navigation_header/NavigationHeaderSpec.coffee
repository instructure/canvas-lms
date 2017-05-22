#
# Copyright (C) 2015 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'jquery'
  'react'
  'react-dom'
  'jsx/navigation_header/Navigation'
], ($, React, ReactDOM, Navigation) ->

  wrapper = document.getElementById('fixtures')
  $(wrapper).append('<div id="holder">')
  componentHolder = document.getElementById('holder')

  renderComponent = ->
    Nav = React.createElement(Navigation)
    ReactDOM.render(Nav, componentHolder)

  QUnit.module 'GlobalNavigation',
    setup: ->
      # Need to setup the global nav stuff we are testing
      @$inbox_data = $('<a id="global_nav_conversations_link" href="/conversations" class="ic-app-header__menu-list-link">' +
                      '<div class="menu-item-icon-container"><span class="menu-item__badge" style="display: none">0</span>' +
                      '</div></a>')
      $(wrapper).append(@$inbox_data)
      @server = sinon.fakeServer.create()
      window.ENV.current_user_id = 10
      ENV.current_user_disabled_inbox = false
      response =
        unread_count: 10
      @server.respondWith("GET", /unread/, [200, { "Content-Type": "application/json" }, JSON.stringify(response)])

    teardown: ->
      @server.restore()
      ReactDOM.unmountComponentAtNode componentHolder
      $('#holder').remove()
      @$inbox_data.remove()

  test 'it renders', ->
    @component = renderComponent()
    ok @component.isMounted()

  test 'shows the inbox badge when necessary', ->
    @component = renderComponent()
    @server.respond()
    $badge = $('#global_nav_conversations_link').find('.menu-item__badge')
    ok $badge.is(':visible')

  test 'does not show the inbox badge when the user has opted out of notifications', ->
    ENV.current_user_disabled_inbox = true
    @component = renderComponent()
    @server.respond()
    $badge = $('#global_nav_conversations_link').find('.menu-item__badge')
    notOk $badge.is(':visible')

