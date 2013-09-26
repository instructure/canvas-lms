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
      dates = $(@searchForm.el).toJSON()
      @$overview.hide()
      @$overview.html(overviewTemplate(
        user: @searchForm.model.get('name')
        start_date: @getDisplayDateText(dates.start_time,
                                        I18n.t('from_beginning', "the beginning"))
        end_date: @getDisplayDateText(dates.end_time,
                                      I18n.t('to_now', "now"))
      ))
      @$overview.show()

    getDisplayDateText: (dateInfo, fallbackText) =>
      if dateInfo
        $.parseFromISO($.unfudgeDateForProfileTimezone(dateInfo).toISOString()).datetime_formatted
      else
        fallbackText
