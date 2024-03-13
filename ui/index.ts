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
import {captureException} from '@sentry/browser'

// true modules that we use in this file
import ready from '@instructure/ready'
import splitAssetString from '@canvas/util/splitAssetString'
import {Mathml} from '@instructure/canvas-rce'
import {Capabilities as C, up} from '@canvas/engine'
import {loadReactRouter} from './boot/initializers/router'
import loadLocale from './loadLocale'
import featureBundles from './featureBundles'
// @ts-expect-error
import pluginBundles from 'plugin-bundles-generated'

// these are all things that either define global $.whatever or $.fn.blah
// methods or set something up that other code expects to exist at runtime.
// so they have to be ran before any other app code runs.
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/jquery/jquery.instructure_forms'
import './boot/initializers/ajax_errors'
import './boot/initializers/activateKeyClicks'
import './boot/initializers/activateTooltips'
import './boot/initializers/injectAuthTokenIntoForms'

interface CustomWindow extends Window {
  bundles: string[]
  deferredBundles: string[]
  canvasReadyState: 'loading' | 'complete' | undefined
}

declare let window: CustomWindow

if (typeof ENV !== 'undefined' && ENV.MOMENT_LOCALE && ENV.MOMENT_LOCALE !== 'en') {
  loadLocale('moment/locale/' + ENV.MOMENT_LOCALE)
}

function loadBundle(bundle: string): void {
  if (typeof featureBundles[bundle] === 'function') {
    featureBundles[bundle]()
  } else if (typeof pluginBundles[bundle] === 'function') {
    pluginBundles[bundle]()
  } else {
    throw new Error("couldn't find bundle " + bundle)
  }
}

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
    window.bundles.push = (...items) => {
      items.forEach(loadBundle)
      return items.length
    }
    window.bundles.forEach(loadBundle)
    ready(afterDocumentReady)
  },
  requires: [C.I18n],
}).catch((e: Error) => {
  // eslint-disable-next-line no-console
  console.error(
    `Canvas front-end did not successfully start! Did you add any new bundles to ui/featureBundles.ts? (${e.message})`
  )
  captureException(e)
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

  const helpButton = document.querySelector('.help_dialog_trigger')
  if (helpButton !== null) helpButton.addEventListener('click', openHelpDialog)

  loadReactRouter()
  loadNewUserTutorials()

  if (!ENV.FEATURES.explicit_latex_typesetting) {
    setupMathML()
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
  import('./boot/initializers/warnOnIncompleteRegistration')
}

// TODO: remove the need for this
// it is only used in submissions
if (ENV.badge_counts) {
  import('./boot/initializers/showBadgeCounts')
}

// Load and then display the Canvas help dialog if the user has requested it
async function openHelpDialog(event: Event): Promise<void> {
  event.preventDefault()
  try {
    const {default: helpDialog} = await import('./boot/initializers/enableHelpDialog')
    helpDialog.open()
  } catch (e) {
    /* eslint-disable no-console */
    console.error('Help dialog could not be displayed')
    console.error(e)
    captureException(e)
    /* eslint-enable no-console */
  }
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

;(window.requestIdleCallback || window.setTimeout)(async () => {
  await import('./boot/initializers/runOnEveryPageButDontBlockAnythingElse')
  advanceReadiness('asyncInitializers')
})
