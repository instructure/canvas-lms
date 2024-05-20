// @ts-nocheck
/*
 * Copyright (C) 2016 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import htmlEscape from '@instructure/html-escape'
import 'jquery.cookie'

const I18n = useI18nScope('shared.flash_notices')

function updateAriaLive(this: RailsFlashNotificationsHelper, {polite} = {polite: false}) {
  if (this.screenreaderHolderReady()) {
    const value = polite ? 'polite' : 'assertive'
    // instui FocusRegionManager throws aria-hidden on everything outside a Dialog when opened
    // removing it here sees that it's done whenever screenreader alerts are displayed
    $(this.screenreader_holder).removeAttr('aria-hidden')
    // adding the aria-live before removing the aria-hidden breaks some screenreaders
    $(this.screenreader_holder).attr('aria-live', value)
  }
}

class RailsFlashNotificationsHelper {
  holder: HTMLElement | null

  screenreader_holder: HTMLElement | null

  constructor() {
    this.holder = null
    this.screenreader_holder = null
  }

  initHolder() {
    const $current_holders = $('#flash_message_holder')

    if ($current_holders.length === 0) {
      this.holder = null
    } else {
      this.holder = $current_holders[0]

      $(this.holder).on('click', '.close_link', event => {
        event.preventDefault()
      })

      $(this.holder).on('click', '.flash-message-container', event => {
        if ($(event.currentTarget).hasClass('no_close')) {
          return
        }

        if ($(event.currentTarget).hasClass('unsupported_browser')) {
          $.cookie('unsupported_browser_dismissed', true, {path: '/'})
        }

        $(event.currentTarget).stop(true, true).remove()
      })
    }
  }

  holderReady(): this is {holder: HTMLElement} {
    return this.holder != null
  }

  createNode(type, content, timeout, cssOptions = {}, classes = '') {
    if (this.holderReady()) {
      const node = this.generateNodeHTML(type, content)

      $(node)
        .addClass(classes)
        .appendTo($(this.holder))
        .css({zIndex: 2, ...cssOptions})
        .show('fast')
        .delay(ENV.flashAlertTimeout || timeout || 7000)
        .fadeOut('slow', function () {
          $(this).remove()
        })
    }
  }

  generateNodeHTML(type, content) {
    const icon = this.getIconType(type)
    const escapedType = htmlEscape(type)
    const escapedIcon = htmlEscape(icon)
    const escapedContent = this.escapeContent(content)
    const closeButtonLabel = htmlEscape(I18n.t('Close'))

    // see generateScreenreaderNodeHtml() for SR features
    return `
      <div class="ic-flash-${escapedType} flash-message-container" aria-hidden="true">
        <div class="ic-flash__icon">
          <i class="icon-${escapedIcon}"></i>
        </div>
        ${escapedContent}
        <button type="button" class="Button Button--icon-action close_link" aria-label="${closeButtonLabel}">
          <i class="icon-x"></i>
        </button>
      </div>
    `.trim()
  }

  getIconType(type) {
    if (type === 'success') {
      return 'check'
    } else if (type === 'warning' || type === 'error') {
      return 'warning'
    } else {
      return 'info'
    }
  }

  initScreenreaderHolder() {
    const $current_screenreader_holders = $('#flash_screenreader_holder')

    if ($current_screenreader_holders.length === 0) {
      this.screenreader_holder = null
    } else {
      this.screenreader_holder = $current_screenreader_holders[0]
      this.setScreenreaderAttributes()
    }
  }

  screenreaderHolderReady(): this is {screenreader_holder: HTMLElement} {
    return this.screenreader_holder != null
  }

  createScreenreaderNode(content, closable = true) {
    if (this.screenreaderHolderReady()) {
      updateAriaLive.call(this, {polite: false})
      const node = $(this.generateScreenreaderNodeHTML(content, closable))
      node.appendTo($(this.screenreader_holder))

      window.setTimeout(() => {
        // Accessibility attributes must be removed for the deletion of the node
        // and then reapplied because JAWS/IE will not respect the
        // "aria-relevant" attribute and read when the node is deleted if
        // the attributes are in place
        this.resetScreenreaderAttributes()
        node.remove()
        this.setScreenreaderAttributes()
      }, 10000)
    }
  }

  setScreenreaderAttributes() {
    if (this.screenreaderHolderReady()) {
      // These attributes are added for accessibility.  However, adding them
      // to the DOM at load causes some screenreaders to read "alert" when
      // the page is loaded.  That is why these attributes are added here.
      $(this.screenreader_holder).attr('role', 'alert')
      $(this.screenreader_holder).attr('aria-live', 'assertive')
      $(this.screenreader_holder).attr('aria-relevant', 'additions')
      $(this.screenreader_holder).attr('class', 'screenreader-only')
      $(this.screenreader_holder).attr('aria-atomic', true as any)
    }
  }

  resetScreenreaderAttributes() {
    if (this.screenreaderHolderReady()) {
      $(this.screenreader_holder).removeAttr('role')
      $(this.screenreader_holder).removeAttr('aria-live')
      $(this.screenreader_holder).removeAttr('aria-relevant')
      $(this.screenreader_holder).removeAttr('class')
      $(this.screenreader_holder).removeAttr('aria-atomic')
    }
  }

  createScreenreaderNodeExclusive(content, polite = false) {
    if (this.screenreaderHolderReady()) {
      updateAriaLive.call(this, {polite})
      this.screenreader_holder.innerHTML = ''
      const node = $(this.generateScreenreaderNodeHTML(content, false))
      node.appendTo($(this.screenreader_holder))
    }
  }

  generateScreenreaderNodeHTML(content, closable) {
    let closeContent
    if (closable) {
      closeContent = I18n.t('Close')
    } else {
      closeContent = ''
    }

    return `<span>${this.escapeContent(content)}${htmlEscape(closeContent)}</span>`
  }

  /*
xsslint safeString.method escapeContent
*/
  escapeContent(content) {
    if (content.hasOwnProperty('html')) {
      return content.html
    } else {
      return htmlEscape(content)
    }
  }
}

export default RailsFlashNotificationsHelper
