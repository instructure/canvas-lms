#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

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
        $.datetimeString($.unfudgeDateForProfileTimezone(dateInfo))
      else
        fallbackText
