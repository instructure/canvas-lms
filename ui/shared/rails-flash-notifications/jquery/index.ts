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
import type {FlashNotificationContent, FlashNotice} from '../../global/env/EnvNotices'
import NotificationsHelper from './helper'
import {FLASH_NOTICE_STORAGE_KEY} from '../index'

export {addFlashNoticeForNextPage} from '../index'

declare global {
  interface JQueryStatic {
    /**
     * Pops up a small notification box at the top of the screen.
     */
    flashMessage: (message: FlashNotificationContent, timeout?: number) => void

    /**
     * Like flashMessage, but escapes html even if 'html' field given
     * To be used when the input comes from an external source (e.g. an LTI tool)
     */
    flashMessageSafe: (message: FlashNotificationContent, timeout?: number) => void

    /**
     *  Pops up a small error box at the top of the screen.
     */
    flashError: (message: FlashNotificationContent, timeout?: number) => void

    /**
     * Like flashError, but escapes html even if 'html' field given
     * To be used when the input comes from an external source (e.g. an LTI tool)
     */
    flashErrorSafe: (message: FlashNotificationContent, timeout?: number) => void

    /**
     * Pops up a small warning box at the top of the screen.
     */
    flashWarning: (message: FlashNotificationContent, timeout?: number) => void

    /**
     * Like flashWarning, but escapes html even if 'html' field given
     * To be used when the input comes from an external source (e.g. an LTI tool)
     */
    flashWarningSafe: (message: FlashNotificationContent, timeout?: number) => void

    screenReaderFlashMessage: (message: FlashNotificationContent) => void

    screenReaderFlashError: (message: FlashNotificationContent) => void

    /**
     * This is for when you want to clear the flash message content prior to
     * updating it with new content.  Makes it so the SR only reads this one
     * message.
     */
    screenReaderFlashMessageExclusive: (message: FlashNotificationContent, polite?: boolean) => void
  }
}

const helper = new NotificationsHelper()

export function initFlashContainer() {
  helper.initHolder()
  helper.initScreenreaderHolder()
}

function makeSafeHtml(contentString: string | {html: string}) {
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

// Like flashMessage, but escapes html even if 'html' field given
// To be used when the input comes from an external source (e.g. an LTI tool)
$.flashMessageSafe = function (contentString, timeout) {
  contentString = makeSafeHtml(contentString)
  $.flashMessage(contentString.toString(), timeout)
}

// Pops up a small error box at the top of the screen.
$.flashError = function (content, timeout) {
  helper.createNode('error', content, timeout)
  createScreenreaderNodeWithDelay(content)
}

// Like flashError, but escapes html even if 'html' field given
// To be used when the input comes from an external source (e.g. an LTI tool)
$.flashErrorSafe = function (contentString, timeout) {
  contentString = makeSafeHtml(contentString)
  $.flashError(contentString.toString(), timeout)
}

// Pops up a small warning box at the top of the screen.
$.flashWarning = function (content, timeout = 3000) {
  helper.createNode('warning', content, timeout)
  createScreenreaderNodeWithDelay(content)
}

// Like flashWarning, but escapes html even if 'html' field given
// To be used when the input comes from an external source (e.g. an LTI tool)
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

function renderFlashNotification(notice: FlashNotice): void {
  const timeout = notice.content instanceof Object && notice.content.timeout
  helper.createNode(notice.type, notice.content, timeout, undefined, notice.classes)
  createScreenreaderNodeWithDelay(notice.content, false)
}

export function renderServerNotifications() {
  if (ENV?.notices) ENV.notices.forEach(renderFlashNotification)
  const storedNotices = sessionStorage.getItem(FLASH_NOTICE_STORAGE_KEY)
  if (storedNotices) {
    try {
      const notices: Array<FlashNotice> = JSON.parse(storedNotices)
      notices.forEach(renderFlashNotification)
    } catch {
      // ignore invalid JSON, which should never happen
    }
    sessionStorage.removeItem(FLASH_NOTICE_STORAGE_KEY)
  }
}

/**
 *
 * @param {FlashNotificationContent} content
 * @param {boolean} closable
 */
function createScreenreaderNodeWithDelay(content: FlashNotificationContent, closable = true) {
  setTimeout(() => helper.createScreenreaderNode(content, closable), 100)
}

export default $
