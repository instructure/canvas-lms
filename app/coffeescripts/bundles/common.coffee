require [
  'jquery'
  'underscore'

  # true modules that we manage in this file
  'Backbone'
  'compiled/helpDialog'
  'compiled/tours'

  # modules that do their own thing on every page that simply need to
  # be required
  'translations/_core_en'
  'jquery.ajaxJSON'
  'vendor/firebugx'
  'jquery.google-analytics'
  'vendor/swfobject/swfobject'
  'reminders'
  'jquery.instructure_forms'
  'instructure'
  'ajax_errors'
  'page_views'
  'compiled/license_help'
  'compiled/behaviors/authenticity_token'
  'compiled/behaviors/ujsLinks'
  'compiled/behaviors/admin-links'
  'compiled/behaviors/activate'
  'compiled/behaviors/elementToggler'
  'compiled/behaviors/tooltip'
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
], ($, _, Backbone, helpDialog, tours) ->
  helpDialog.initTriggers()
  tours.init()

  $('#skip_navigation_link').on 'click', ->
    $($(this).attr('href')).attr('tabindex', -1).focus()

  # TODO: remove this code once people have had time to update their logo-related
  # custom css. see related code in app/stylesheets/base/_#header.sass.
  $logo = $('#header-logo')
  if $logo.length > 0 and $logo.css('background-image').match(/\/canvas\/header_canvas_logo\.png/)
    $logo.addClass('original')

  # new styles only - show and hide the courses vertical menu when the user clicks the hamburger button
  # This was in the courses bundle, but it sometimes needs to work in places that don't
  # load that bundle.
  #
  WIDE_BREAKPOINT = 1200

  setMenuItemTabIndex = ($menuElement) ->
    # in testing this, it seems that $(document).width() returns 15px less than what it should.
    if ($('body').hasClass('course-menu-expanded') || $(document).width() >= WIDE_BREAKPOINT - 15)
      $menuElement.attr('tabIndex', 0)
    else
      $menuElement.attr('tabIndex', -1)

  $(document).ready( ->
    return unless window.ENV.use_new_styles?

    $('#section-tabs li a').each((index, element) ->
      setMenuItemTabIndex($(element))
    )
  )

  if window.ENV.use_new_styles?
    $("body").on('click', '#courseMenuToggle', ->
      $("body").toggleClass("course-menu-expanded")
      $('#section-tabs li a').each((index, element) ->
        setMenuItemTabIndex($(element))
      )
    )

    $(window).on('resize', _.debounce( ->
      $('#section-tabs li a').each((index, element) ->
        setMenuItemTabIndex($(element))
      )
    , 50)
    )


  ##
  # Backbone routes
  $('body').on 'click', '[data-pushstate]', (event) ->
    event.preventDefault()
    Backbone.history.navigate $(this).attr('href'), yes
