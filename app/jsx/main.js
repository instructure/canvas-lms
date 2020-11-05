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

import 'setWebpackCdnHost'
import 'jquery.instructure_jquery_patches' // this needs to be before anything else that requires jQuery
import './appBootstrap'

// true modules that we use in this file
import $ from 'jquery'
import ready from '@instructure/ready'
import Backbone from 'Backbone'
import splitAssetString from 'compiled/str/splitAssetString'
import mathml from 'mathml'
import preventDefault from 'compiled/fn/preventDefault'
import loadBundle from 'bundles-generated'

// these are all things that either define global $.whatever or $.fn.blah
// methods or set something up that other code expects to exist at runtime.
// so they have to be ran before any other app code runs.
import 'translations/_core_en'
import 'jquery.ajaxJSON'
import 'jquery.instructure_forms'
import 'ajax_errors'
import 'compiled/behaviors/activate'
import 'compiled/behaviors/tooltip'

// This is because most pages use this and by having it all in it's own chunk it makes webpack
// split out a ton of stuff (like @instructure/ui-view) into multiple chunks because its chunking
// algorithm decides that because that chunk would either be too small or it would cause more than
// our maxAsyncRequests it should concat it into mutlple parents.
require.include('./bundles/navigation_header')

if (!window.bundles) window.bundles = []
window.bundles.push = loadBundle
// process any queued ones
window.bundles.forEach(loadBundle)

if (ENV.csp)
  // eslint-disable-next-line promise/catch-or-return
  import('./account_settings/alert_enforcement').then(({default: setupCSP}) =>
    setupCSP(window.document)
  )
if (ENV.INCOMPLETE_REGISTRATION) import('compiled/registration/incompleteRegistrationWarning')
if (ENV.badge_counts) import('compiled/badge_counts')

$('html').removeClass('scripts-not-loaded')

$('.help_dialog_trigger').click(event => {
  event.preventDefault()
  // eslint-disable-next-line promise/catch-or-return
  import('compiled/helpDialog').then(({default: helpDialog}) => helpDialog.open())
})

// Backbone routes
$('body').on(
  'click',
  '[data-pushstate]',
  preventDefault(function() {
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
  import('./new_user_tutorial/initializeNewUserTutorials').then(
    ({default: initializeNewUserTutorials}) => {
      initializeNewUserTutorials()
    }
  )
}

;(window.requestIdleCallback || window.setTimeout)(() => {
  import('./runOnEveryPageButDontBlockAnythingElse')
})

ready(() => {
  ;(window.deferredBundles || []).forEach(loadBundle)

  // This is in a setTimeout to have it run on the next time through the event loop
  // so that the code that actually renders the user_content runs first,
  // because it has to be rendered before we can check if isMathOnPage
  setTimeout(() => {
    window.dispatchEvent(processNewMathEvent)
  }, 0)

  const processNewMathEvent = new Event(mathml.processNewMathEventName)
  const observer = new MutationObserver((mutationList, _observer) => {
    for (const m in mutationList) {
      if (mutationList[m]?.addedNodes?.length) {
        window.dispatchEvent(processNewMathEvent)
      }
    }
  })

  observer.observe(document.body, {
    childList: true,
    subtree: true
  })
})
