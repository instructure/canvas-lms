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

import './boot/initializers/setWebpackCdnHost'
import '@canvas/jquery/jquery.instructure_jquery_patches' // this needs to be before anything else that requires jQuery
import './boot'

// true modules that we use in this file
import $ from 'jquery'
import ready from '@instructure/ready'
import Backbone from '@canvas/backbone'
import splitAssetString from '@canvas/util/splitAssetString'
import mathml from 'mathml'
import preventDefault from 'prevent-default'
import loadBundle from 'bundles-generated'
import {isolate} from '@canvas/sentry'

// these are all things that either define global $.whatever or $.fn.blah
// methods or set something up that other code expects to exist at runtime.
// so they have to be ran before any other app code runs.
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/forms/jquery/jquery.instructure_forms'
import './boot/initializers/ajax_errors'
import './boot/initializers/activateKeyClicks'
import './boot/initializers/activateTooltips'
import './boot/initializers/injectAuthTokenIntoForms'

window.canvasReadyState = 'loading'
window.dispatchEvent(new CustomEvent('canvasReadyStateChange'))

// Backfill LOCALE from LOCALES
if (!ENV.LOCALE && ENV.LOCALES instanceof Array) ENV.LOCALE = ENV.LOCALES[0]

const readinessTargets = [
  ['asyncInitializers', false],
  ['deferredBundles', false],
  ['localeFiles', false],
  ['localePolyfills', false]
]
const advanceReadiness = target => {
  const entry = readinessTargets.find(x => x[0] === target)

  if (!entry) {
    throw new Error(`Invalid readiness target -- "${target}"`)
  } else if (entry[1]) {
    throw new Error(`Target already marked ready -- "${target}"`)
  }

  entry[1] = true
  window.dispatchEvent(new CustomEvent('canvasReadyStateChange', { detail: target }))

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
  isolate(setupMathML)()
}

function setupMathML() {
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
      new CustomEvent(mathml.processNewMathEventName, {
        detail: {target: document.body}
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
          const processNewMathEvent = new CustomEvent(mathml.processNewMathEventName, {
            detail: {target: node}
          })
          window.dispatchEvent(processNewMathEvent)
        }
      }
    }
  })

  observer.observe(document.body, {
    childList: true,
    subtree: true
  })
}

if (!window.bundles) window.bundles = []

// If you add to this be sure there is support for it in the intl-polyfills package!
const intlSubsystemsInUse = ['DateTimeFormat', 'RelativeTimeFormat', 'NumberFormat']

// Do we have native support in the given Intl subsystem for one of the current
// locale fallbacks?
function noNativeSupport(sys) {
  const locales = [...ENV.LOCALES]
  // 'en' is the final fallback, don't settle for that unless it's the only
  // available locale, in which case there is obviously native support.
  if (locales.length < 1 || (locales.length === 1 && locales[0] === 'en')) return false
  if (locales.slice(-1)[0] === 'en') locales.pop()
  for (const locale of locales) {
    const native = Intl[sys].supportedLocalesOf([locale])
    if (native.length > 0) return false
  }
  return true
}

async function maybePolyfillLocaleThenGo() {
  await import(`../public/javascripts/translations/${ENV.LOCALE}`)
  advanceReadiness('localeFiles')

  // If any Intl subsystem has no native support for the current locale, start
  // trying to polyfill that locale from @formatjs. Note that this (possibly slow)
  // process only executes at all if polyfilling was detected to be necessary.
  if (intlSubsystemsInUse.some(noNativeSupport)) {
    /* eslint-disable no-console */
    try {
      const im = await import('intl-polyfills')
      const result = await im.loadAllLocalePolyfills(ENV.LOCALES, intlSubsystemsInUse)
      result.forEach(r => {
        if (r.error)
          console.error(`${r.subsys} polyfill for locale "${r.locale}" failed: ${r.error}`)
        if (r.source === 'polyfill')
          console.info(`${r.subsys} polyfilled "${r.loaded}" for locale "${r.locale}"`)
      })
    } catch (e) {
      console.error(`Locale polyfill load failed: ${e.message}`)
    }
    /* eslint-enable no-console */
  }

  // After possible polyfilling has completed, now we can start evaluating any
  // queueud JS bundles, arrange for tasks to run after the document is fully ready,
  // and advance the readiness state.
  advanceReadiness('localePolyfills')

  window.bundles.push = loadBundle
  window.bundles.forEach(loadBundle)
  ready(afterDocumentReady)
}

maybePolyfillLocaleThenGo().catch(e =>
  // eslint-disable-next-line no-console
  console.error(`Front-end bundles did not successfully start! (${e.message})`)
)

if (ENV.csp) {
  // eslint-disable-next-line promise/catch-or-return
  import('./boot/initializers/setupCSP').then(({default: setupCSP}) =>
    setupCSP(window.document)
  )
}

if (ENV.INCOMPLETE_REGISTRATION) {
  isolate(() => import('./boot/initializers/warnOnIncompleteRegistration'))()
}

if (ENV.badge_counts) {
  isolate(() => import('./boot/initializers/showBadgeCounts'))()
}

isolate(doRandomThingsToDOM)()

function doRandomThingsToDOM() {
  $('html').removeClass('scripts-not-loaded')

  $('.help_dialog_trigger').click(event => {
    event.preventDefault()
    // eslint-disable-next-line promise/catch-or-return
    import('./boot/initializers/enableHelpDialog').then(({default: helpDialog}) => helpDialog.open())
  })

  // Backbone routes
  $('body').on(
    'click',
    '[data-pushstate]',
    preventDefault(function () {
      Backbone.history.navigate($(this).attr('href'), true)
    })
  )
}

async function loadNewUserTutorials() {
  if (
    window.ENV.NEW_USER_TUTORIALS &&
    window.ENV.NEW_USER_TUTORIALS.is_enabled &&
    window.ENV.context_asset_string &&
    splitAssetString(window.ENV.context_asset_string)[0] === 'courses'
  ) {
    // eslint-disable-next-line promise/catch-or-return
    const {
      default: initializeNewUserTutorials
    } = await import('./features/new_user_tutorial/index')

    initializeNewUserTutorials()
  }
}

;(window.requestIdleCallback || window.setTimeout)(isolate(async () => {
  // eslint-disable-next-line promise/catch-or-return
  await import('./boot/initializers/runOnEveryPageButDontBlockAnythingElse')
  advanceReadiness('asyncInitializers')
}))
