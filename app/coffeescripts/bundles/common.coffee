require [
  # true modules that we manage in this file
  'compiled/widget/courseList'
  'compiled/helpDialog'

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
  'fixed_warning'
  'ajax_errors'
  'page_views'
  'compiled/license_help'
  'compiled/behaviors/ujsLinks'
  'compiled/behaviors/admin-links'
  'compiled/behaviors/elementToggler'
  'compiled/behaviors/upvote-item'
  'compiled/behaviors/repin-item'
  'compiled/behaviors/follow'

  # other stuff several bundles use
  'media_comments'
  'order'
  'jqueryui/effects/core'
  'jqueryui/effects/drop'
  'jqueryui/progressbar'
  'jqueryui/tabs'

  # random modules required by the js_blocks, put them all in here
  # so RequireJS doesn't try to load them before common is loaded
  # in an optimized environment
  'jquery.fancyplaceholder'
  'jqueryui/autocomplete'
  'link_enrollment'
  'media_comments'
  'vendor/jquery.pageless'
  'vendor/jquery.scrollTo'
], (courseList, helpDialog) ->
  courseList.init()
  helpDialog.initTriggers()

