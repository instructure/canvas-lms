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

define ['react', 'jquery', 'prop-types'], (React, $, PropTypes) ->
  stubRouterContext = (Component, props, stubs) ->

    RouterStub = ->
    $.extend(RouterStub, {
      makePath: ->
      makeHref: ->
      transitionTo: ->
      replaceWith: ->
      goBack: ->
      getCurrentPath: ->
      getCurrentRoutes: ->
      getCurrentPathname: ->
      getCurrentParams: ->
      getCurrentQuery: ->
      isActive: ->
    }, stubs)

    React.createClass
      childContextTypes:
        router: PropTypes.func,
        routeDepth: PropTypes.number

      getChildContext: ->
        router: RouterStub,
        routeDepth: 0

      render: ->
        React.createElement(Component, props)
