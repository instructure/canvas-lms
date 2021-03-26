/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import $ from 'jquery'
import LinkContentItem from './models/LinkContentItem'
import ResourceLinkContentItem from './models/ResourceLinkContentItem'
import ImageContentItem from './models/ImageContentItem'
import HtmlFragmentContentItem from './models/HtmlFragmentContentItem'
import {ltiState} from '../../../public/javascripts/lti/post_message/handleLtiPostMessage'

export default class ContentItemProcessor {
  constructor(contentItems, messages, logs, ltiEndpoint, processHandler) {
    this.contentItems = contentItems
    this.messages = messages
    this.logs = logs
    this.ltiEndpoint = ltiEndpoint
    this.processHandler = processHandler
    this.showMessages()
    this.showLogs()
  }

  get loggingEnabled() {
    return ENV && ENV.DEEP_LINKING_LOGGING
  }

  get typeMap() {
    return {
      link: LinkContentItem,
      ltiResourceLink: ResourceLinkContentItem,
      image: ImageContentItem,
      html: HtmlFragmentContentItem
    }
  }

  static fromEvent(event, processHandler) {
    const {content_items, msg, log, errormsg, errorlog, ltiEndpoint, messageType} = event.data

    if (messageType !== 'LtiDeepLinkingResponse') {
      return
    }

    return new this(
      content_items,
      {
        msg,
        errormsg
      },
      {
        log,
        errorlog
      },
      ltiEndpoint,
      processHandler
    )
  }

  process() {
    // close any new tabs/popups that were created by a full window launch
    if (ltiState?.fullWindowProxy) {
      ltiState.fullWindowProxy.close()
    }
    return this.processHandler(...arguments)
  }

  showMessages() {
    if (this.messages.errormsg) {
      $.flashError(this.messages.errormsg)
    }

    if (this.messages.msg) {
      $.flashMessage(this.messages.msg)
    }
  }

  showLogs() {
    if (this.loggingEnabled) {
      if (this.logs.errorlog) {
        console.error(this.logs.errorlog)
      }

      if (this.logs.log) {
        console.log(this.logs.log)
      }
    }
  }
}
