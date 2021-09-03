//
// Copyright (C) 2012 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

// does Rails-style flash message/error boxes that drop down from the top of the screen
import $ from 'jquery'
import NotificationsHelper from './helper'

const helper = new NotificationsHelper()

function initFlashContainer() {
  helper.initHolder()
  helper.initScreenreaderHolder()
}

function makeSafeHtml(contentString) {
  if (typeof contentString === 'object' && contentString.html) {
    return contentString.html
  }
  return contentString
}

// Pops up a small notification box at the top of the screen.
$.flashMessage = function (content, timeout = 3000) {
  helper.createNode('success', content, timeout)
  createScreenreaderNodeWithDelay(content)
}

// Like flashMessage but does escapes html even if 'html' field given to be used
// when the input comes from an external source (e.g. an LTI tool)
$.flashMessageSafe = function (contentString, timeout) {
  contentString = makeSafeHtml(contentString)
  $.flashMessage(contentString.toString(), timeout)
}

// Pops up a small error box at the top of the screen.
$.flashError = function (content, timeout) {
  helper.createNode('error', content, timeout)
  createScreenreaderNodeWithDelay(content)
}

// Like flashError but does escapes html even if 'html' field given To be used
// when the input comes from an external source (e.g. an LTI tool)
$.flashErrorSafe = function (contentString, timeout) {
  contentString = makeSafeHtml(contentString)
  $.flashError(contentString.toString(), timeout)
}

// Pops up a small warning box at the top of the screen.
$.flashWarning = function (content, timeout = 3000) {
  helper.createNode('warning', content, timeout)
  createScreenreaderNodeWithDelay(content)
}

// Like flashWarning but does escapes html even if 'html' field given to be used
// when the input comes from an external source (e.g. an LTI tool)
$.flashWarningSafe = function (contentString, timeout) {
  contentString = makeSafeHtml(contentString)
  $.flashWarning(contentString.toString(), timeout)
}

$.screenReaderFlashMessage = content => helper.createScreenreaderNode(content, false)

$.screenReaderFlashError = content => helper.createScreenreaderNode(content, false)

// This is for when you want to clear the flash message content prior to
// updating it with new content.  Makes it so the SR only reads this one
// message.
$.screenReaderFlashMessageExclusive = (content, polite = false) =>
  helper.createScreenreaderNodeExclusive(content, polite)

$.initFlashContainer = () => initFlashContainer()

function renderServerNotifications() {
  if (typeof ENV !== 'undefined' && ENV && ENV.notices) {
    ENV.notices.forEach(notice => {
      const timeout = notice.content instanceof Object && notice.content.timeout
      helper.createNode(notice.type, notice.content, timeout, undefined, notice.classes)
      createScreenreaderNodeWithDelay(notice.content, false)
    })
  }
}

function createScreenreaderNodeWithDelay(content, closable = true) {
  setTimeout(() => helper.createScreenreaderNode(content, closable), 100)
}

$(initFlashContainer)
$(() => setTimeout(renderServerNotifications, 100))

export default $
