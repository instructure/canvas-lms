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

// these are all things that either define global $.whatever or $.fn.blah
// methods or set something up that other code expects to exist at runtime.
// so they have to be ran before any other app code runs.
import 'translations/_core_en'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/forms/jquery/jquery.instructure_forms'
import './boot/initializers/ajax_errors'
import './boot/initializers/activateKeyClicks'
import './boot/initializers/activateTooltips'

window.canvasReadyState = 'loading'
window.dispatchEvent(new CustomEvent('canvasReadyStateChange'))

const readinessTargets = [
  ['asyncInitializers', false],
  ['deferredBundles', false],
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

  if (readinessTargets.every(x => x[1])) {
    window.canvasReadyState = 'complete'
    window.dispatchEvent(new CustomEvent('canvasReadyStateChange'))
  }
}

// This is because most pages use this and by having it all in it's own chunk it makes webpack
// split out a ton of stuff (like @instructure/ui-view) into multiple chunks because its chunking
// algorithm decides that because that chunk would either be too small or it would cause more than
// our maxAsyncRequests it should concat it into mutlple parents.
require.include('./features/navigation_header')

if (!window.bundles) window.bundles = []
window.bundles.push = loadBundle
// process any queued ones
window.bundles.forEach(loadBundle)

if (ENV.csp)
  // eslint-disable-next-line promise/catch-or-return
  import('./boot/initializers/setupCSP').then(({default: setupCSP}) => setupCSP(window.document))
if (ENV.INCOMPLETE_REGISTRATION) import('./boot/initializers/warnOnIncompleteRegistration')
if (ENV.badge_counts) import('./boot/initializers/showBadgeCounts')

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

if (
  window.ENV.NEW_USER_TUTORIALS &&
  window.ENV.NEW_USER_TUTORIALS.is_enabled &&
  window.ENV.context_asset_string &&
  splitAssetString(window.ENV.context_asset_string)[0] === 'courses'
) {
  // eslint-disable-next-line promise/catch-or-return
  import('./features/new_user_tutorial/index').then(({default: initializeNewUserTutorials}) => {
    initializeNewUserTutorials()
  })
}

;(window.requestIdleCallback || window.setTimeout)(() => {
  // eslint-disable-next-line promise/catch-or-return
  import('./boot/initializers/runOnEveryPageButDontBlockAnythingElse').then(() =>
    advanceReadiness('asyncInitializers')
  )
})

// Load Intl polyfills if necessary given the ENV.LOCALE. Advance the readiness
// state whether that worked or not.

/* eslint-disable no-console */
import('intl-polyfills')
  .then(im => im.loadAllLocalePolyfills(ENV.LOCALE))
  .catch(e => {
    console.error(
      `Problem loading locale polyfill for ${ENV.LOCALE}, falling back to ${e.result.locale}`
    )
    console.error(e.message)
  })
  .finally(() => advanceReadiness('localePolyfills'))
/* eslint-enable no-console */

ready(() => {
  // eslint-disable-next-line promise/catch-or-return
  Promise.all((window.deferredBundles || []).map(loadBundle)).then(() =>
    advanceReadiness('deferredBundles')
  )

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
  setTimeout(() => {
    window.dispatchEvent(
      new CustomEvent(mathml.processNewMathEventName, {
        detail: {target: document.body}
      })
    )
  }, 0)

  const observer = new MutationObserver((mutationList, _observer) => {
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
})
