//
// Copyright (C) 2013 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import Backbone from 'Backbone'
import $ from 'jquery'
import I18n from 'i18n!comm_messages'
import template from 'jst/accounts/admin_tools/commMessagesContentPane'
import overviewTemplate from 'jst/accounts/admin_tools/commMessagesSearchOverview'
import 'jquery.instructure_date_and_time'

export default class CommMessagesContentPaneView extends Backbone.View {
  static initClass() {
    this.child('searchForm', '#commMessagesSearchForm')
    this.child('resultsView', '#commMessagesSearchResults')

    this.prototype.template = template

    this.prototype.els = {'#commMessagesSearchOverview': '$overview'}
  }

  attach() {
    return this.collection.on('setParams', this.fetchMessages.bind(this))
  }

  fetchMessages() {
    this.buildOverviewText()
    return this.collection.fetch().fail(this.onFail.bind(this))
  }

  onFail() {
    // Received a 404, empty the collection and don't let the paginated
    // view try to fetch more.
    this.collection.reset()
    return this.resultsView.detachScroll()
  }

  buildOverviewText() {
    const dates = $(this.searchForm.el).toJSON()
    this.$overview.hide()
    this.$overview.html(
      overviewTemplate({
        user: this.searchForm.model.get('name'),
        start_date: this.getDisplayDateText(
          dates.start_time,
          I18n.t('from_beginning', 'the beginning')
        ),
        end_date: this.getDisplayDateText(dates.end_time, I18n.t('to_now', 'now'))
      })
    )
    return this.$overview.show()
  }

  getDisplayDateText(dateInfo, fallbackText) {
    if (dateInfo) {
      return $.datetimeString($.unfudgeDateForProfileTimezone(dateInfo))
    } else {
      return fallbackText
    }
  }
}
CommMessagesContentPaneView.initClass()
