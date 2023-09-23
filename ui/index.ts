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

// main entry for frontend code

import './boot/initializers/setWebpackCdnHost'
import '@canvas/jquery/jquery.instructure_jquery_patches' // this needs to be before anything else that requires jQuery
import './boot'

// true modules that we use in this file
import $ from 'jquery'
import ready from '@instructure/ready'
import splitAssetString from '@canvas/util/splitAssetString'
import {Mathml} from '@instructure/canvas-rce'
// @ts-expect-error
import loadBundle from 'bundles-generated'
import {isolate} from '@canvas/sentry'
import {Capabilities as C, up} from '@canvas/engine'

// these are all things that either define global $.whatever or $.fn.blah
// methods or set something up that other code expects to exist at runtime.
// so they have to be ran before any other app code runs.
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/forms/jquery/jquery.instructure_forms'
import './boot/initializers/ajax_errors'
import './boot/initializers/activateKeyClicks'
import './boot/initializers/activateTooltips'
import './boot/initializers/injectAuthTokenIntoForms'
import './boot/initializers/router'

window.canvasReadyState = 'loading'
window.dispatchEvent(new CustomEvent('canvasReadyStateChange'))

// Let's just fire these off right now, so anything that might block
// on them can resume as quickly as possible.
up({
  up: () => {
    advanceReadiness('capabilities')
    // list of all bundles the current page needs
    //   populated by app/helpers/application_helper.rb
    if (!window.bundles) window.bundles = []
    window.bundles.push = loadBundle
    window.bundles.forEach(loadBundle)
    ready(afterDocumentReady)
  },
  requires: [C.I18n],
}).catch((e: Error) => {
  // eslint-disable-next-line no-console
  console.error(`Canvas front-end did not successfully start! (${e.message})`)
})

const readinessTargets = [
  ['asyncInitializers', false],
  ['deferredBundles', false],
  ['capabilities', false],
]
const advanceReadiness = (target: string) => {
  const entry = readinessTargets.find(x => x[0] === target)

  if (!entry) {
    throw new Error(`Invalid readiness target -- "${target}"`)
  } else if (entry[1]) {
    throw new Error(`Target already marked ready -- "${target}"`)
  }

  entry[1] = true
  window.dispatchEvent(new CustomEvent('canvasReadyStateChange', {detail: target}))

  if (readinessTargets.every(x => x[1])) {
    window.canvasReadyState = 'complete'
    window.dispatchEvent(new CustomEvent('canvasReadyStateChange'))
  }
}

function afterDocumentReady() {
  // eslint-disable-next-line promise/catch-or-return
  Promise.all((window.deferredBundles || []).map(loadBundle)).then(() => {
    advanceReadiness('deferredBundles')
  })

  isolate(loadNewUserTutorials)()

  if (!ENV.FEATURES.explicit_latex_typesetting) {
    isolate(setupMathML)()
  }
}

function setupMathML() {
  const features = {
    new_math_equation_handling: !!ENV?.FEATURES?.new_math_equation_handling,
    explicit_latex_typesetting: !!ENV?.FEATURES?.explicit_latex_typesetting,
  }
  const config = {locale: ENV?.LOCALE || 'en'}

  // LS-1662: there are math equations on the page that
  // we don't see, so remain invisible and aren't
  // typeset my MathJax. Let's trick Canvas into knowing
  // there's math on the page by putting some there.
  if (!/quizzes\/\d*\/edit/.test(window.location.pathname)) {
    if (document.querySelector('.math_equation_latex')) {
      const elem = document.createElement('math')
      elem.innerHTML = '&nbsp;'
      document.body.appendChild(elem)
    }
  }

  if (!ENV?.FEATURES?.new_math_equation_handling) {
    // This is in a setTimeout to have it run on the next time through the event loop
    // so that the code that actually renders the user_content runs first,
    // because it has to be rendered before we can check if isMathMLOnPage
    setTimeout(() => {
      const mathml = new Mathml(features, config)
      if (mathml.isMathOnPage()) mathml.loadMathJax(undefined)
    }, 5)
    return
  }

  // This is in a setTimeout to have it run on the next time through the event loop
  // so that the code that actually renders the user_content runs first,
  // because it has to be rendered before we can check if isMathOnPage
  let processedBodyMath = false
  setTimeout(() => {
    processedBodyMath = true
    window.dispatchEvent(
      new CustomEvent(Mathml.processNewMathEventName, {
        detail: {target: document.body, features, config},
      })
    )
  }, 0)

  const observer = new MutationObserver((mutationList, _observer) => {
    if (!processedBodyMath) return
    for (let m = 0; m < mutationList.length; ++m) {
      if (mutationList[m]?.addedNodes?.length) {
        const addedNodes = mutationList[m].addedNodes
        for (let n = 0; n < addedNodes.length; ++n) {
          const node = addedNodes[n]
          if (node.nodeType !== Node.ELEMENT_NODE) continue
          const processNewMathEvent = new CustomEvent(Mathml.processNewMathEventName, {
            detail: {target: node, features, config},
          })
          window.dispatchEvent(processNewMathEvent)
        }
      }
    }
  })

  observer.observe(document.body, {
    childList: true,
    subtree: true,
  })
}

if (ENV.csp) {
  // eslint-disable-next-line promise/catch-or-return
  import('./boot/initializers/setupCSP').then(({default: setupCSP}) => setupCSP(window.document))
}

if (ENV.INCOMPLETE_REGISTRATION) {
  isolate(() => import('./boot/initializers/warnOnIncompleteRegistration'))()
}

// TODO: remove the need for this
// it is only used in submissions
if (ENV.badge_counts) {
  isolate(() => import('./boot/initializers/showBadgeCounts'))()
}

isolate(doRandomThingsToDOM)()

function doRandomThingsToDOM() {
  $('.help_dialog_trigger').click(event => {
    event.preventDefault()
    // eslint-disable-next-line promise/catch-or-return
    import('./boot/initializers/enableHelpDialog').then(({default: helpDialog}) =>
      helpDialog.open()
    )
  })
}

async function loadNewUserTutorials() {
  if (
    window.ENV.NEW_USER_TUTORIALS &&
    window.ENV.NEW_USER_TUTORIALS.is_enabled &&
    window.ENV.context_asset_string &&
    splitAssetString(window.ENV.context_asset_string)?.[0] === 'courses'
  ) {
    const {default: initializeNewUserTutorials} = await import('./features/new_user_tutorial/index')

    initializeNewUserTutorials()
  }
}

;(window.requestIdleCallback || window.setTimeout)(
  isolate(async () => {
    await import('./boot/initializers/runOnEveryPageButDontBlockAnythingElse')
    advanceReadiness('asyncInitializers')
  })
)
