#
# Copyright (C) 2012 - present Instructure, Inc.
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

# does Rails-style flash message/error boxes that drop down from the top of the screen
define [
  'jquery'
  'underscore'
  'compiled/fn/preventDefault'
  'str/htmlEscape'
  'jsx/railsFlashNotificationsHelper'
  'jqueryui/effects/drop'
  'jquery.cookie'
], ($, _, preventDefault, htmlEscape, NotificationsHelper) ->

  helper = new NotificationsHelper

  initFlashContainer = ->
    helper.initHolder()
    helper.initScreenreaderHolder()
  initFlashContainer()

  # Pops up a small notification box at the top of the screen.
  $.flashMessage = (content, timeout = 3000) ->
    helper.createNode("success", content, timeout)
    createScreenreaderNodeWithDelay(content)

  # Pops up a small error box at the top of the screen.
  $.flashError = (content, timeout) ->
    helper.createNode("error", content, timeout)
    createScreenreaderNodeWithDelay(content)

  # Pops up a small warning box at the top of the screen.
  $.flashWarning = (content, timeout = 3000) ->
    helper.createNode("warning", content, timeout)
    createScreenreaderNodeWithDelay(content)

  $.screenReaderFlashMessage = (content) ->
    helper.createScreenreaderNode(content, false)

  $.screenReaderFlashError = (content) ->
    helper.createScreenreaderNode(content, false)

  # This is for when you want to clear the flash message content prior to
  # updating it with new content.  Makes it so the SR only reads this one
  # message.
  $.screenReaderFlashMessageExclusive = (content) ->
    helper.createScreenreaderNodeExclusive(content)

  $.initFlashContainer = ->
    initFlashContainer()

  renderServerNotifications = ->
    if ENV?.notices?
      for notice in ENV.notices
        helper.createNode(notice.type, notice.content)
        createScreenreaderNodeWithDelay(notice.content)

  createScreenreaderNodeWithDelay = (content) ->
    setTimeout( ->
      helper.createScreenreaderNode(content)
    , 100)

  $ ->
    setTimeout(renderServerNotifications, 500)

