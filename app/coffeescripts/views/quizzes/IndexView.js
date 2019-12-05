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

import I18n from 'i18n!quizzesIndexView'
import $ from 'jquery'
import _ from 'underscore'
import Backbone from 'Backbone'
import template from 'jst/quizzes/IndexView'
import '../../jquery.rails_flash_notifications'
import React from 'react'
import ReactDOM from 'react-dom'
import ContentTypeExternalToolTray from 'jsx/shared/ContentTypeExternalToolTray'
import {ltiState} from '../../../../public/javascripts/lti/post_message/handleLtiPostMessage'

export default class IndexView extends Backbone.View {
  static initClass() {
    this.prototype.template = template

    this.prototype.el = '#content'

    this.child('assignmentView', '[data-view=assignment]')
    this.child('openView', '[data-view=open]')
    this.child('noQuizzesView', '[data-view=no_quizzes]')
    this.child('surveyView', '[data-view=surveys]')

    this.prototype.events = {
      'keyup #searchTerm': 'keyUpSearch',
      'mouseup #searchTerm': 'keyUpSearch',
      'click .header-bar-right .menu_tool_link': 'openExternalTool'
    }

    this.prototype.keyUpSearch = _.debounce(function() {
      this.filterResults()
      return this.announceCount()
    }, 200)
    // ie10 x-close workaround
  }

  initialize() {
    this.filterResults = this.filterResults.bind(this)
    this.announceCount = this.announceCount.bind(this)
    super.initialize(...arguments)
    this.options.hasNoQuizzes =
      this.assignmentView.collection.length + this.openView.collection.length === 0
    this.options.hasAssignmentQuizzes = this.assignmentView.collection.length > 0
    this.options.hasOpenQuizzes = this.openView.collection.length > 0
    this.quizIndexPlacements = ENV.quiz_index_menu_tools != null ? ENV.quiz_index_menu_tools : []
    return (this.options.hasSurveys = this.surveyView.collection.length > 0)
  }

  views() {
    return [this.options.assignmentView, this.options.openView, this.options.surveyView]
  }

  filterResults() {
    return _.each(this.views(), view => {
      view.filterResults($('#searchTerm').val())
    })
  }

  announceCount() {
    const searchTerm = $('#searchTerm').val()
    if (searchTerm === '' || searchTerm === null) return

    const matchingQuizCount = _.reduce(
      this.views(),
      (runningCount, view) => {
        return runningCount + view.matchingCount(searchTerm)
      },
      0
    )
    return this.announceMatchingQuizzes(matchingQuizCount)
  }

  announceMatchingQuizzes(numQuizzes) {
    const msg = I18n.t(
      {
        one: '1 quiz found.',
        other: '%{count} quizzes found.',
        zero: 'No matching quizzes found.'
      },
      {count: numQuizzes}
    )
    return $.screenReaderFlashMessageExclusive(msg)
  }

  toJSON() {
    const json = super.toJSON(...arguments)
    json.quizIndexPlacements = this.quizIndexPlacements
    return json
  }

  openExternalTool(ev) {
    if (ev != null) {
      ev.preventDefault()
    }
    const tool = this.quizIndexPlacements.find(t => t.id === ev.target.dataset.toolId)
    this.setExternalToolTray(tool, $('.al-trigger')[0])
  }

  reloadPage() {
    window.location.reload()
  }

  setExternalToolTray(tool, returnFocusTo) {
    const handleDismiss = () => {
      this.setExternalToolTray(null)
      returnFocusTo.focus()
      if (ltiState?.tray?.refreshOnClose) {
        this.reloadPage()
      }
    }

    ReactDOM.render(
      <ContentTypeExternalToolTray
        tool={tool}
        placement="quiz_index_menu"
        acceptedResourceTypes={['quiz']}
        targetResourceType="quiz"
        allowItemSelection={false}
        selectableItems={[]}
        onDismiss={handleDismiss}
        open={tool !== null}
      />,
      $('#external-tool-mount-point')[0]
    )
  }
}
IndexView.initClass()
