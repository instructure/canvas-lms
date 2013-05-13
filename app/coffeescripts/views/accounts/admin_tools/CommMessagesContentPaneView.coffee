define [
  'Backbone'
  'jquery'
  'i18n!comm_messages'
  'jst/accounts/admin_tools/commMessagesContentPane'
  'jst/accounts/admin_tools/commMessagesSearchOverview'
  'jquery.instructure_date_and_time'
], (Backbone, $, I18n, template, overviewTemplate) ->
  class CommMessagesContentPaneView extends Backbone.View
    @child 'searchForm', '#commMessagesSearchForm'
    @child 'resultsView', '#commMessagesSearchResults'

    template: template

    els:
      '#commMessagesSearchOverview': '$overview'

    attach: ->
      @collection.on 'setParams', @fetchMessages
    fetchMessages: =>
      @buildOverviewText()
      @collection.fetch().fail @onFail

    onFail: =>
      # Received a 404, empty the collection and don't let the paginated
      # view try to fetch more.
      @collection.reset()
      @resultsView.detachScroll()

    buildOverviewText: =>
      # perform AJAX request to get user's name for visual feedback of who's
      # data was fetched.
      dfd = $.ajax
        url: "/users/#{$('#userIdSearchField').val()}.json"
        type: 'GET'
        success: @renderOverviewDisplay
        error: @$overview.hide()
      dfd.promise()

    renderOverviewDisplay: (response) =>
      dates = $(@searchForm.el).toJSON()
      @$overview.hide()
      @$overview.html(overviewTemplate(
        user: response.name
        start_date: @getDisplayDateText(dates.start_time,
                                        I18n.t('from_beginning', "the beginning"))
        end_date: @getDisplayDateText(dates.end_time,
                                      I18n.t('to_now', "now"))
      ))
      @$overview.show()

    getDisplayDateText: (dateInfo, fallbackText) =>
      if dateInfo
        $.parseFromISO($.dateToISO8601UTC($.unfudgeDateForProfileTimezone(dateInfo))).datetime_formatted
      else
        fallbackText
