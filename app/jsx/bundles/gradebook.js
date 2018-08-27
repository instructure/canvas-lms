/*
 * Copyright (C) 2011 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery'
import Backbone from 'Backbone'
import React from 'react'
import ReactDOM from 'react-dom'
import Paginator from '../shared/components/Paginator'
import userSettings from 'compiled/userSettings'
import Gradebook from 'compiled/gradebook/Gradebook'
import NavigationPillView from 'compiled/views/gradebook/NavigationPillView'
import OutcomeGradebookView from 'compiled/views/gradebook/OutcomeGradebookView'

const GradebookRouter = Backbone.Router.extend({
  routes: {
    '': 'tab',
    'tab-:viewName': 'tab'
  },

  initialize () {
    this.isLoaded = false
    this.views = {}
    this.views.assignment = new Gradebook(ENV.GRADEBOOK_OPTIONS)

    if (ENV.GRADEBOOK_OPTIONS.outcome_gradebook_enabled) {
      this.views.outcome = this.initOutcomes()
      this.renderPagination(0, 0)
    }
  },

  initOutcomes () {
    const book = new OutcomeGradebookView({
      el: $('.outcome-gradebook-container'),
      gradebook: this.views.assignment,
      router: this
    })
    book.render()
    this.navigation = new NavigationPillView({el: $('.gradebook-navigation')})
    this.navigation.on('pillchange', this.handlePillChange.bind(this))
    return book
  },

  renderPagination(page, pageCount) {
    ReactDOM.render(
      <Paginator page={page} pageCount={pageCount} loadPage={(p) => this.views.outcome.loadPage(p)} />,
      document.getElementById("outcome-gradebook-paginator")
    )
  },

  handlePillChange (viewname) {
    if (viewname) this.navigate(`tab-${viewname}`, {trigger: true})
  },

  tab (viewName) {
    if (!viewName) viewName = userSettings.contextGet('gradebook_tab')
    window.tab = viewName
    if ((viewName !== 'outcome') || !this.views.outcome) { viewName = 'assignment' }
    if (this.navigation) { this.navigation.setActiveView(viewName) }
    $('.assignment-gradebook-container, .outcome-gradebook-container').addClass('hidden')
    $(`.${viewName}-gradebook-container`).removeClass('hidden')
    $('#outcome-gradebook-paginator').toggleClass('hidden', viewName !== 'outcome')
    this.views[viewName].onShow()
    userSettings.contextSet('gradebook_tab', viewName)
  }
})

const router = new GradebookRouter()
Backbone.history.start()
