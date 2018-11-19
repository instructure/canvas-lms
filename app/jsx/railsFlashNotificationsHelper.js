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

import I18n from 'i18n!shared.flash_notices'
import $ from 'jquery'
import _ from 'underscore'
import htmlEscape from 'str/htmlEscape'
import 'jqueryui/effects/drop'
import 'jquery.cookie'

function updateAriaLive({polite} = {polite: false}) {
  if (this.screenreaderHolderReady()) {
    const value = polite ? 'polite' : 'assertive'
    $(this.screenreader_holder).attr('aria-live', value)
  }
}

class RailsFlashNotificationsHelper {
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

      $(this.holder).on('click', 'li', event => {
        if ($(event.currentTarget).hasClass('no_close')) {
          return
        }

        if ($(event.currentTarget).hasClass('unsupported_browser')) {
          $.cookie('unsupported_browser_dismissed')
        }

        $(event.currentTarget)
          .stop(true, true)
          .remove()
      })
    }
  }

  holderReady() {
    return this.holder != null
  }

  createNode(type, content, timeout, cssOptions = {}) {
    if (this.holderReady()) {
      const node = this.generateNodeHTML(type, content)

      $(node)
        .appendTo($(this.holder))
        .css(_.extend({zIndex: 2}, cssOptions))
        .show('fast')
        .delay(timeout || 7000)
        .fadeOut('slow', function() {
          $(this).remove()
        })
    }
  }

  generateNodeHTML(type, content) {
    const icon = this.getIconType(type)

    // See generateScreenreaderNodeHtml for SR features
    return `
        <li class="ic-flash-${htmlEscape(type)}" aria-hidden="true">
          <div class="ic-flash__icon">
            <i class="icon-${htmlEscape(icon)}"></i>
          </div>
          ${this.escapeContent(content)}
          <button type="button" class="Button Button--icon-action close_link">
            <i class="icon-x"></i>
          </button>
        </li>
      `
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

  screenreaderHolderReady() {
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
      $(this.screenreader_holder).attr('aria-atomic', 'false')
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

    return `
        <span>
          ${this.escapeContent(content)}
          ${htmlEscape(closeContent)}
        </span>
      `
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
