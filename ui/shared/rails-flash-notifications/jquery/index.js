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

// Pops up a small notification box at the top of the screen.
$.flashMessage = function(content, timeout = 3000) {
  helper.createNode('success', content, timeout)
  createScreenreaderNodeWithDelay(content)
}

// Pops up a small error box at the top of the screen.
$.flashError = function(content, timeout) {
  helper.createNode('error', content, timeout)
  createScreenreaderNodeWithDelay(content)
}

// Pops up a small warning box at the top of the screen.
$.flashWarning = function(content, timeout = 3000) {
  helper.createNode('warning', content, timeout)
  createScreenreaderNodeWithDelay(content)
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
