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
  'react'
  'react-dom'
  'react-addons-test-utils'
  'jsx/shared/FriendlyDatetime'
  'i18nObj'
  'helpers/I18nStubber'
], (React, ReactDOM, TestUtils, FriendlyDatetime, I18n, I18nStubber) ->

  QUnit.module 'FriendlyDatetime',
    setup: ->
      I18nStubber.clear()

  test "parses datetime from a string", ->
    fDT = React.createFactory(FriendlyDatetime)
    rendered = TestUtils.renderIntoDocument(fDT(dateTime: '1970-01-17'))
    equal $(rendered.time).find('.visible-desktop').text(), "Jan 17, 1970", "converts to readable format"
    equal $(rendered.time).find('.hidden-desktop').text(), "1/17/1970", "converts to readable format"
    ReactDOM.unmountComponentAtNode(rendered.time.parentNode)

  test "parses datetime from a Date", ->
    fDT = React.createFactory(FriendlyDatetime)
    rendered = TestUtils.renderIntoDocument(fDT(dateTime: new Date(1431570574)))
    equal $(rendered.time).find('.visible-desktop').text(), "Jan 17, 1970", "converts to readable format"
    equal $(rendered.time).find('.hidden-desktop').text(), "1/17/1970", "converts to readable format"
    ReactDOM.unmountComponentAtNode(rendered.time.parentNode)
