/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {useScope as useI18nScope} from '@canvas/i18n'
import {debounce} from 'lodash'

const I18n = useI18nScope('common_bundle')

/**
 * Sets up CSP enforcement for iframes and alerts end users to csp failures
 */
export default function setupCSP(rootElement) {
  const csp = ENV.csp
  if (csp) {
    const cspViolationFunction = () => {
      showFlashAlert({
        message: I18n.t(
          'Content on this page violates the security policy, contact your admin for assistance.'
        ),
        type: 'error',
      })
    }

    const setupCSPForIframes = debounce(
      () =>
        Array.from(rootElement.querySelectorAll('iframe.attachment-html-iframe')).forEach(frame => {
          if (!frame.getAttribute('csp')) {
            frame.setAttribute('csp', csp)
          }
        }),
      300
    )

    // Set up CSP on any iframes currently on the page
    setupCSPForIframes()

    // Handle page level violations
    rootElement.addEventListener('securitypolicyviolation', cspViolationFunction)

    // Set up handling for any iframes that might be added to the page
    // Sometimes an iframe being added in React doesn't trigger nodes being added... :(
    // So we just run this function on all mutations (though it is debounced)
    const cspMutationObserver = new MutationObserver(setupCSPForIframes)

    cspMutationObserver.observe(rootElement, {
      childList: true,
      subtree: true,
    })
  }
}
