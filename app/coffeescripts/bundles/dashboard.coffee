require [
  'underscore'
  'Backbone',
  'jquery',
  'i18n!dashboard'
  'compiled/util/newCourseForm'
  'jst/dashboard/show_more_link'
  'jquery.disableWhileLoading'
], (_, {View}, $, I18n, newCourseForm, showMoreTemplate) ->

  if ENV.DASHBOARD_SIDEBAR_URL
    rightSide = $('#right-side')
    rightSide.disableWhileLoading(
      $.get ENV.DASHBOARD_SIDEBAR_URL , (data) ->
        rightSide.html data
        newCourseForm()
    )

  class DashboardView extends View

    el: document.body

    events:
      'click .stream_header': 'expandDetails'
      'click .stream_header .links a': 'stopPropagation'
      'click .stream-details': 'handleDetailsClick'
      'beforeremove': 'updateCategoryCounts' # ujsLinks event

    initialize: ->
      super
      # setup all 'Show More' links to reflect currently being collapsed.
      $('.toggle-details').each (idx, elm) =>
        @setShowMoreLink $(elm), false

    expandDetails: (event) ->
      header   = $(event.currentTarget)
      # since toggling, isExpanded is the opposite of the current DOM state
      isExpanded = not (header.attr('aria-expanded') == 'true')
      header.attr('aria-expanded', isExpanded)
      details  = header.next('.details_container')
      details.toggle(isExpanded)
      # Set the link contents. Second param for being currently expanded or collapsed
      @setShowMoreLink header.find('.toggle-details'), isExpanded

    setShowMoreLink: ($link, isExpanded) ->
      $link.html showMoreTemplate({expanded: isExpanded}) if $link

    handleDetailsClick: (event) ->
      row = $(event.target).closest('tr')
      link = row.find('a')

    # TODO: switch recent items to client rendering and skip all this
    # ridiculous dom manip that is likely to just get worse
    updateCategoryCounts: (event) ->
      parent = $(event.target).closest('li[class^=stream-]')
      items = parent.find('tbody tr').filter(':visible')
      if items.length
        parent.find('.count').text items.length
      else
        parent.remove()

  new DashboardView

