require [
  'jquery'
  'underscore'
  'i18n!common'

  # true modules that we manage in this file
  'Backbone'
  'compiled/helpDialog'

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

  # other stuff several bundles use
  'media_comments'
  'jqueryui/effects/drop'
  'jqueryui/progressbar'
  'jqueryui/tabs'
  'compiled/registration/incompleteRegistrationWarning'
  'moment'

  # random modules required by the js_blocks, put them all in here
  # so RequireJS doesn't try to load them before common is loaded
  # in an optimized environment
  'jquery.fancyplaceholder'
  'jqueryui/autocomplete'
  'link_enrollment'
  'media_comments'
  'vendor/jquery.pageless'
  'vendor/jquery.scrollTo'
  'compiled/badge_counts'
], ($, _, I18n, Backbone, helpDialog) ->
  helpDialog.initTriggers()

  $('#skip_navigation_link').on 'click', ->
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
    $('body').toggleClass("course-menu-expanded")
    
    # update course menu and toggle for accessibility
    courseMenuExpanded = $('body').hasClass('course-menu-expanded')
    courseMenuToggleText = if courseMenuExpanded then I18n.t("Hide courses menu") else I18n.t("Show courses menu")
    courseMenuToggle = $('#courseMenuToggle')
    courseMenuToggle.attr("aria-label", courseMenuToggleText)
    courseMenuToggle.attr("title", courseMenuToggleText)
    $('#left-side').css({display: if courseMenuExpanded then 'block' else 'none'})

    resetMenuItemTabIndexes()


  ##
  # Backbone routes
  $('body').on 'click', '[data-pushstate]', (event) ->
    event.preventDefault()
    Backbone.history.navigate $(this).attr('href'), yes
