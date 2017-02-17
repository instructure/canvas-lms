require [
  # true modules that we use in this file
  'jquery'
  'underscore'
  'i18n!common'
  'Backbone'
  'compiled/helpDialog'
  'jsx/subnav_menu/updateSubnavMenuToggle'

  # modules that do their own thing on every page that simply need to
  # be required
  'translations/_core_en'
  'jquery.ajaxJSON'
  'jquery.google-analytics'
  'vendor/swfobject/swfobject'
  'reminders'
  'jquery.instructure_forms'
  'instructure'
  'ajax_errors'
  'page_views'
  'compiled/behaviors/authenticity_token'
  'compiled/behaviors/ujsLinks'
  'compiled/behaviors/admin-links'
  'compiled/behaviors/activate'
  'compiled/behaviors/elementToggler'
  'compiled/behaviors/tooltip'
  'compiled/behaviors/ic-super-toggle'
  'compiled/behaviors/instructure_inline_media_comment'
  'compiled/behaviors/ping'
  'LtiThumbnailLauncher'
  'compiled/badge_counts'

  # Other stuff several bundles use.
  # If any of these really arn't used on most pages,
  # we should remove them from this list, since this
  # loads them on every page
  'media_comments'
  'jqueryui/effects/drop'
  'jqueryui/progressbar'
  'jqueryui/tabs'
  'compiled/registration/incompleteRegistrationWarning'
  'moment'
], ($, _, I18n, Backbone, helpDialog, updateSubnavMenuToggle) ->

  helpDialog.initTriggers()

  $('#skip_navigation_link').on 'click', (event) ->
    # preventDefault so we dont change the hash
    # this will make nested apps that use the hash happy
    event.preventDefault()
    $($(this).attr('href')).attr('tabindex', -1).focus()

  # show and hide the courses vertical menu when the user clicks the hamburger button
  # This was in the courses bundle, but it sometimes needs to work in places that don't
  # load that bundle.
  WIDE_BREAKPOINT = 1200

  resetMenuItemTabIndexes = ->
    # in testing this, it seems that $(document).width() returns 15px less than what it should.
    tabIndex = if ($('body').hasClass('course-menu-expanded') || $(document).width() >= WIDE_BREAKPOINT - 15)
      0
    else
      -1
    $('#section-tabs li a').attr('tabIndex', tabIndex)

  $(resetMenuItemTabIndexes)
  $(window).on('resize', _.debounce(resetMenuItemTabIndexes, 50))
  $('body').on 'click', '#courseMenuToggle', ->
    $('body').toggleClass('course-menu-expanded')
    updateSubnavMenuToggle()
    $('#left-side').css({display: if $('body').hasClass('course-menu-expanded') then 'block' else 'none'})

    resetMenuItemTabIndexes()

  ##
  # Backbone routes
  $('body').on 'click', '[data-pushstate]', (event) ->
    event.preventDefault()
    Backbone.history.navigate $(this).attr('href'), yes
