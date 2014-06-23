require [
  'jquery'

  # true modules that we manage in this file
  'Backbone'
  'compiled/widget/courseList'
  'compiled/helpDialog'
  'compiled/tours'

  # modules that do their own thing on every page that simply need to
  # be required
  'translations/_core'
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
  'compiled/behaviors/ujsLinks'
  'compiled/behaviors/admin-links'
  'compiled/behaviors/activate'
  'compiled/behaviors/elementToggler'
  'compiled/behaviors/tooltip'
  'compiled/behaviors/instructure_inline_media_comment'

  # other stuff several bundles use
  'media_comments'
  'jqueryui/effects/drop'
  'jqueryui/progressbar'
  'jqueryui/tabs'
  'compiled/registration/incompleteRegistrationWarning'

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
], ($, Backbone, courseList, helpDialog, tours) ->
  courseList.init()
  helpDialog.initTriggers()
  tours.init()

  $('#skip_navigation_link').on 'click', ->
    $($(this).attr('href')).attr('tabindex', -1).focus()

  # TODO: remove this code once people have had time to update their logo-related
  # custom css. see related code in app/stylesheets/base/_#header.sass.
  $logo = $('#header-logo')
  if $logo.length > 0 and $logo.css('background-image').match(/\/canvas\/header_canvas_logo\.png/)
    $logo.addClass('original')

  ##
  # Backbone routes
  $('body').on 'click', '[data-pushstate]', (event) ->
    event.preventDefault()
    Backbone.history.navigate $(this).attr('href'), yes
