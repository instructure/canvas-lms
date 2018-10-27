/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

// true modules that we use in this file
import $ from 'jquery'
import _ from 'underscore'
import Backbone from 'Backbone'
import updateSubnavMenuToggle from '../subnav_menu/updateSubnavMenuToggle'
import splitAssetString from 'compiled/str/splitAssetString'
import {isMathMLOnPage, loadMathJax} from 'mathml'

// modules that do their own thing on every page that simply need to be required
import 'translations/_core_en'
import 'jquery.ajaxJSON'
import 'jquery.google-analytics'
import 'reminders'
import 'jquery.instructure_forms'
import 'instructure'
import 'ajax_errors'
import 'page_views'
import 'compiled/behaviors/authenticity_token'
import 'compiled/behaviors/ujsLinks'
import 'compiled/behaviors/admin-links'
import 'compiled/behaviors/activate'
import 'compiled/behaviors/elementToggler'
import 'compiled/behaviors/tooltip'
import 'compiled/behaviors/ic-super-toggle'
import 'compiled/behaviors/instructure_inline_media_comment'
import 'compiled/behaviors/ping'
import 'compiled/behaviors/broken-images'
import 'LtiThumbnailLauncher'
import 'compiled/badge_counts'

// Other stuff several bundles use.
// If any of these really arn't used on most pages,
// we should remove them from this list, since this
// loads them on every page
import 'media_comments'
import 'jqueryui/effects/drop'
import 'jqueryui/progressbar'
import 'jqueryui/tabs'
import 'compiled/registration/incompleteRegistrationWarning'
import 'moment'

$('html').removeClass('scripts-not-loaded')

$('.help_dialog_trigger').click((event) => {
  event.preventDefault()
  require.ensure([], (require) => {
    const helpDialog = require('compiled/helpDialog')
    helpDialog.open()
  }, 'helpDialogAsyncChunk')
})

$('#skip_navigation_link').on('click', function (event) {
  // preventDefault so we dont change the hash
  // this will make nested apps that use the hash happy
  event.preventDefault()
  $($(this).attr('href')).attr('tabindex', -1).focus()
})

// show and hide the courses vertical menu when the user clicks the hamburger button
// This was in the courses bundle, but it sometimes needs to work in places that don't
// load that bundle.
const WIDE_BREAKPOINT = 1200

function resetMenuItemTabIndexes () {
  // in testing this, it seems that $(document).width() returns 15px less than what it should.
  const tabIndex = (
    $('body').hasClass('course-menu-expanded') ||
    $(document).width() >= WIDE_BREAKPOINT - 15
  ) ? 0 : -1
  $('#section-tabs li a').attr('tabIndex', tabIndex)
}

$(resetMenuItemTabIndexes)
$(window).on('resize', _.debounce(resetMenuItemTabIndexes, 50))
$('body').on('click', '#courseMenuToggle', () => {
  $('body').toggleClass('course-menu-expanded')
  updateSubnavMenuToggle()
  $('#left-side').css({
    display: $('body').hasClass('course-menu-expanded') ? 'block' : 'none'
  })

  resetMenuItemTabIndexes()
})

// Backbone routes
$('body').on('click', '[data-pushstate]', function (event) {
  event.preventDefault()
  Backbone.history.navigate($(this).attr('href'), true)
})

if (
  window.ENV.NEW_USER_TUTORIALS &&
  window.ENV.NEW_USER_TUTORIALS.is_enabled &&
  (window.ENV.context_asset_string && (splitAssetString(window.ENV.context_asset_string)[0] === 'courses'))
) {
  require.ensure([], (require) => {
    const initializeNewUserTutorials = require('../new_user_tutorial/initializeNewUserTutorials')
    initializeNewUserTutorials()
  }, 'NewUserTutorialsAsyncChunk')
}

// edge < 15 does not support css vars
// edge >= 15 claims to, but is currently broken
const edge = window.navigator.userAgent.indexOf("Edge") > -1
const supportsCSSVars = !edge && window.CSS && window.CSS.supports && window.CSS.supports('(--foo: red)')
if (!supportsCSSVars) {
  require.ensure([], (require) => {
    window.canvasCssVariablesPolyfill = require('../canvasCssVariablesPolyfill')
  }, 'canvasCssVariablesPolyfill')
}

$(() => {
  if (isMathMLOnPage()) loadMathJax('TeX-MML-AM_HTMLorMML')
})
