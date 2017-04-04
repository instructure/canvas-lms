// true modules that we use in this file
import $ from 'jquery'
import _ from 'underscore'
import I18n from 'i18n!common'
import Backbone from 'Backbone'
import helpDialog from 'compiled/helpDialog'
import updateSubnavMenuToggle from 'jsx/subnav_menu/updateSubnavMenuToggle'
import initializeNewUserTutorials from 'jsx/new_user_tutorial/initializeNewUserTutorials'

// modules that do their own thing on every page that simply need to be required
import 'translations/_core_en'
import 'jquery.ajaxJSON'
import 'jquery.google-analytics'
import 'vendor/swfobject/swfobject'
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
import 'LtiThumbnailLauncher'
import 'compiled/badge_counts'
import 'instructure-ui/lib/themes/canvas'

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


helpDialog.initTriggers()

initializeNewUserTutorials()

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
