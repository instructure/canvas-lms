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
      $.get ENV.DASHBOARD_SIDEBAR_URL , (html) ->
        rightSide.html html
        newCourseForm()
    )

  class DashboardView extends View

    el: document.body

    events:
      'click .stream_header': 'toggleDetails'
      'click .stream_header .links a': 'stopPropagation'
      'click .stream-details': 'handleDetailsClick'
      'click .close_conference_link': 'closeConference'
      'beforeremove': 'updateCategoryCounts' # ujsLinks event

    initialize: ->
      super
      # setup all 'Show More' links to reflect currently being collapsed.
      $('.stream-category').each (idx, elm) =>
        @setShowMoreLink $(elm)

    toggleDetails: (event) ->
      header   = $(event.currentTarget)
      # since toggling, isExpanded is the opposite of the current DOM state
      isExpanded = not (header.attr('aria-expanded') == 'true')
      header.attr('aria-expanded', isExpanded)
      details  = header.next('.details_container')
      details.toggle(isExpanded)
      # if expanded, focus first link in detail area
      if isExpanded
        details.find('a:first').focus()
      # Set the link contents. Second param for being currently expanded or collapsed
      @setShowMoreLink header.closest('.stream-category'), isExpanded

    setShowMoreLink: ($category) ->
      return unless $category
      # determine if currently expanded
      isExpanded = $category.find('.details_container').is(':visible')
      # go up to stream-category to build the text to display
      categoryName = $category.data('category')
      count = parseInt($category.find('.count:first').text())
      assistiveText = @getCategoryText(categoryName, count, !isExpanded)
      $link = $category.find('.toggle-details')
      $link.html showMoreTemplate({expanded: isExpanded, assistiveText: assistiveText})

    getCategoryText: (category, count, forExpand) ->
      if category == 'Announcement'
        if forExpand
          I18n.t("announcements_expand", {
            one: "Expand %{count} announcement",
            other: "Expand %{count} announcements"}, {count: count})
        else
          I18n.t("announcements_collapse", {
            one: "Collapse %{count} announcement",
            other: "Collapse %{count} announcements"}, {count: count})
      else if category == 'Conversation'
        if forExpand
          I18n.t("conversations_expand", {
            one: "Expand %{count} conversation message",
            other: "Expand %{count} conversation messages"}, {count: count})
        else
          I18n.t("conversations_collapse", {
            one: "Collapse %{count} conversation message",
            other: "Collapse %{count} conversation messages"}, {count: count})
      else if category == 'Assignment'
        if forExpand
          I18n.t("assignments_expand", {
            one: "Expand %{count} assignment notification",
            other: "Expand %{count} assignment notifications"}, {count: count})
        else
          I18n.t("assignments_collapse", {
            one: "Collapse %{count} assignment notification",
            other: "Collapse %{count} assignment notifications"}, {count: count})
      else if category == 'DiscussionTopic'
        if forExpand
          I18n.t("discussions_expand", {
            one: "Expand %{count} discussion",
            other: "Expand %{count} discussions"}, {count: count})
        else
          I18n.t("discussions_collapse", {
            one: "Collapse %{count} discussion",
            other: "Collapse %{count} discussions"}, {count: count})
      else
        ''

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
      @setShowMoreLink $(event.target).closest('.stream-category')

    closeConference: (e) ->
      e.preventDefault()
      return if !confirm(I18n.t('confirm.close', "Are you sure you want to end this conference?\n\nYou will not be able to reopen it."))
      link = $(e.currentTarget)
      $.ajaxJSON(link.attr('href'), "POST", {}, (data) =>
        link.parents('.conference.global-message').hide()
      )
  new DashboardView

