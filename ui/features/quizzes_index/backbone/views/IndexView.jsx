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

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import '@canvas/jquery/jquery.ajaxJSON'
import {debounce, reduce, forEach} from 'lodash'
import Backbone from '@canvas/backbone'
import template from '../../jst/IndexView.handlebars'
import '@canvas/rails-flash-notifications'
import React from 'react'
import ReactDOM from 'react-dom'
import {Alert} from '@instructure/ui-alerts'
import {Text} from '@instructure/ui-text'
import ContentTypeExternalToolTray from '@canvas/trays/react/ContentTypeExternalToolTray'
import QuizEngineModal from '../../react/QuizEngineModal'
import {ltiState} from '@canvas/lti/jquery/messages'
import getCookie from '@instructure/get-cookie'

const I18n = useI18nScope('quizzesIndexView')

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
      'click .header-bar-right .menu_tool_link': 'openExternalTool',
      'click .choose-quiz-engine': 'createNewQuiz',
      'click .reset-quiz-engine': 'resetQuizEngine',
    }

    this.prototype.keyUpSearch = debounce(function () {
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
    forEach(this.views(), view => {
      view.filterResults($('#searchTerm').val())
    })
  }

  announceCount() {
    const searchTerm = $('#searchTerm').val()
    if (searchTerm === '' || searchTerm === null) return

    const matchingQuizCount = reduce(
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
        zero: 'No matching quizzes found.',
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

  createNewQuiz() {
    const newQuizzesSelected = ENV.NEW_QUIZZES_SELECTED
    if (newQuizzesSelected === null) {
      this.chooseQuizEngine()
    } else if (newQuizzesSelected === 'true') {
      window.location.href = `${ENV.URLS.new_assignment_url}?quiz_lti`
    } else if (newQuizzesSelected === 'false') {
      const authenticity_token = () => getCookie('_csrf_token')
      $.ajaxJSON(
        ENV.URLS.new_quiz_url,
        'POST',
        {authenticity_token: authenticity_token()},
        data => {
          window.location.href = data.url
        }
      )
    } else {
      this.chooseQuizEngine()
    }
  }

  chooseQuizEngine() {
    this.renderQuizEngineModal(true, $('.choose-quiz-engine'))
  }

  resetQuizEngine() {
    const newquizzes_engine = null
    $.ajaxJSON(
      ENV.URLS.new_quizzes_selection,
      'PUT',
      {
        newquizzes_engine_selected: newquizzes_engine,
      },
      () => {
        window.location.reload()
        this.renderQuizEngineSelectionSuccessNotice()
      },
      () => {
        this.renderQuizEngineSelectionFailureNotice()
      }
    )
  }

  renderQuizEngineModal(setOpen, returnFocusTo) {
    const handleDismiss = () => {
      this.renderQuizEngineModal(false)
      returnFocusTo && returnFocusTo.focus()
    }

    ReactDOM.render(
      <QuizEngineModal onDismiss={handleDismiss} setOpen={setOpen} />,
      $('#quiz-modal-mount-point')[0]
    )
  }

  renderQuizEngineSelectionSuccessNotice() {
    $('#flash_message_holder')
      .css('width', '30rem')
      .css('padding-left', '35rem')
      .css('display', 'block')

    ReactDOM.render(
      <Alert variant="success" timeout={4000} transition="fade">
        <Text>{I18n.t(`Your quiz engine choice has been reset!`)}</Text>
      </Alert>,
      $('#flash_message_holder')[0]
    )
  }

  renderQuizEngineSelectionFailureNotice() {
    $('#flash_message_holder')
      .css('width', '30rem')
      .css('padding-left', '35rem')
      .css('display', 'block')
    ReactDOM.render(
      <Alert variant="error" timeout={4000} transition="fade">
        <Text>{I18n.t(`There was a problem resetting your quiz engine choice`)}</Text>
      </Alert>,
      $('#flash_message_holder')[0]
    )
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
