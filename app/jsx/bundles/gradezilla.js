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
import UserSettings from 'compiled/userSettings'
import Gradebook from 'compiled/gradezilla/Gradebook'
import OutcomeGradebookView from 'compiled/views/gradezilla/OutcomeGradebookView'

const getGradebookTab = () => UserSettings.contextGet('gradebook_tab')

const setGradebookTab = view => UserSettings.contextSet('gradebook_tab', view)

class GradebookRouter extends Backbone.Router {
  static initClass () {
    this.prototype.routes = {
      '': 'tab',
      'tab-assignment': 'tabAssignment',
      'tab-outcome': 'tabOutcome',
      '*path': 'tab'
    }
  }

  initialize () {
    this.isLoaded = false
    this.views = {}
    ENV.GRADEBOOK_OPTIONS.assignmentOrOutcome = getGradebookTab()
    ENV.GRADEBOOK_OPTIONS.navigate = this.navigate.bind(this)
    this.views.assignment = new Gradebook(ENV.GRADEBOOK_OPTIONS)
    if (ENV.GRADEBOOK_OPTIONS.outcome_gradebook_enabled) { this.views.outcome = this.initOutcomes() }

    return this
  }

  initOutcomes () {
    const book = new OutcomeGradebookView({el: $('.outcome-gradebook'), gradebook: this.views.assignment})
    book.render()
    return book
  }

  tabOutcome () {
    window.tab = 'outcome'
    $('.assignment-gradebook-container').addClass('hidden')
    $('.outcome-gradebook-container > div').removeClass('hidden')
    this.views.outcome.onShow()
    return setGradebookTab('outcome')
  }

  tabAssignment () {
    window.tab = 'assignment'
    $('.outcome-gradebook-container > div').addClass('hidden')
    $('.assignment-gradebook-container').removeClass('hidden')
    this.views.assignment.onShow()
    return setGradebookTab('assignment')
  }

  tab () {
    let view = getGradebookTab()
    window.tab = view
    if ((view !== 'outcome') || !this.views.outcome) {
      view = 'assignment'
    }
    $('.assignment-gradebook-container, .outcome-gradebook-container > div').addClass('hidden')
    $(`.${view}-gradebook-container, .${view}-gradebook-container div`).removeClass('hidden')
    this.views[view].onShow()
    return setGradebookTab(view)
  }
  }
GradebookRouter.initClass()

new GradebookRouter()
Backbone.history.start()
