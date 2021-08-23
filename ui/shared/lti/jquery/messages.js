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

/* eslint no-console: 0 */

import $ from 'jquery'
import '@canvas/rails-flash-notifications'
import htmlEscape from 'html-escape'
import ToolLaunchResizer from './tool_launch_resizer'
import handleLtiPostMessage from './post_message/handleLtiPostMessage'

let beforeUnloadHandler
function setUnloadMessage(msg) {
  removeUnloadMessage()

  beforeUnloadHandler = function (e) {
    return (e.returnValue = msg || '')
  }
  window.addEventListener('beforeunload', beforeUnloadHandler)
}

function removeUnloadMessage() {
  if (beforeUnloadHandler) {
    window.removeEventListener('beforeunload', beforeUnloadHandler)
    beforeUnloadHandler = null
  }
}

function findDomForWindow(sourceWindow) {
  const iframes = document.getElementsByTagName('IFRAME')
  for (let i = 0; i < iframes.length; i += 1) {
    if (iframes[i].contentWindow === sourceWindow) {
      return iframes[i]
    }
  }
  return null
}

export function ltiMessageHandler(e) {
  if (e.data.source && e.data.source === 'react-devtools-bridge') {
    return
  }

  if (e.data.messageType) {
    handleLtiPostMessage(e)
    return
  }

  // Legacy post message handlers
  let message
  try {
    message = typeof e.data === 'string' ? JSON.parse(e.data) : e.data
  } catch (err) {
    // unparseable message may not be meant for our handlers
    return
  }

  try {
    switch (message.subject) {
      case 'lti.frameResize':
        const toolResizer = new ToolLaunchResizer()
        var height = message.height
        if (height <= 0) height = 1

        const container = toolResizer
          .tool_content_wrapper(message.token || e.origin)
          .data('height_overridden', true)
        // If content.length is 0 then jquery didn't the tool wrapper.
        if (container.length > 0) {
          toolResizer.resize_tool_content_wrapper(height, container)
        } else {
          // Attempt to find an embedded iframe that matches the event source.
          const iframe = findDomForWindow(e.source)
          if (iframe) {
            if (typeof height === 'number') {
              height += 'px'
            }
            iframe.height = height
            iframe.style.height = height
          }
        }
        break

      case 'lti.fetchWindowSize': {
        const iframe = findDomForWindow(e.source)
        if (iframe) {
          message.height = window.innerHeight
          message.width = window.innerWidth
          message.offset = $('.tool_content_wrapper').offset()
          message.footer = $('#fixed_bottom').height() || 0
          message.scrollY = window.scrollY
          const strMessage = JSON.stringify(message)

          iframe.contentWindow.postMessage(strMessage, '*')
        }
        break
      }

      case 'lti.showModuleNavigation':
        if (message.show === true || message.show === false) {
          $('.module-sequence-footer').toggle(message.show)
        }
        break

      case 'lti.scrollToTop':
        $('html,body').animate(
          {
            scrollTop: $('.tool_content_wrapper').offset().top
          },
          'fast'
        )
        break

      case 'lti.setUnloadMessage':
        setUnloadMessage(htmlEscape(message.message))
        break

      case 'lti.removeUnloadMessage':
        removeUnloadMessage()
        break

      case 'lti.screenReaderAlert':
        $.screenReaderFlashMessageExclusive(
          typeof message.body === 'string' ? message.body : JSON.stringify(message.body)
        )
        break

      case 'lti.enableScrollEvents': {
        const iframe = findDomForWindow(e.source)
        if (iframe) {
          let timeout
          window.addEventListener(
            'scroll',
            () => {
              // requesting animation frames effectively debounces the scroll messages being sent
              if (timeout) {
                window.cancelAnimationFrame(timeout)
              }

              timeout = window.requestAnimationFrame(() => {
                const msg = JSON.stringify({
                  subject: 'lti.scroll',
                  scrollY: window.scrollY
                })
                iframe.contentWindow.postMessage(msg, '*')
              })
            },
            false
          )
        }
        break
      }
    }
  } catch (err) {
    ;(console.error || console.log).call(console, 'invalid message received from')
  }
}

export function monitorLtiMessages() {
  window.addEventListener('message', e => {
    if (e.data !== '') ltiMessageHandler(e)
  })
}
