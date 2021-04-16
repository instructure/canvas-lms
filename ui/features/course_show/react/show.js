/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import CourseHomeDialog from '@canvas/course-homepage/react/Dialog'
import HomePagePromptContainer from '@canvas/course-homepage/react/Prompt'
import createStore from '@canvas/util/createStore'
import $ from 'jquery'
import '@canvas/rails-flash-notifications'
import I18n from 'i18n!courses_show'
import React from 'react'
import PropTypes from 'prop-types'
import ReactDOM from 'react-dom'
import {initializePlanner, renderToDoSidebar} from '@instructure/canvas-planner'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import apiUserContent from '@canvas/util/jquery/apiUserContent'
import * as apiClient from '@canvas/courses/courseAPIClient'

const defaultViewStore = createStore({
  selectedDefaultView: ENV.COURSE.default_view,
  savedDefaultView: ENV.COURSE.default_view
})

class ChooseHomePageButton extends React.Component {
  state = {
    dialogOpen: false
  }

  static propTypes = {
    store: PropTypes.object.isRequired
  }

  render() {
    return (
      <div>
        <button
          type="button"
          className="Button button-sidebar-wide choose_home_page_link"
          ref={b => (this.chooseButton = b)}
          onClick={this.onClick}
        >
          <i className="icon-target" aria-hidden="true" />
          &nbsp;{I18n.t('Choose Home Page')}
        </button>
        {this.state.dialogOpen && (
          <CourseHomeDialog
            store={this.props.store}
            open={this.state.dialogOpen}
            onRequestClose={this.onClose}
            courseId={ENV.COURSE.id}
            wikiFrontPageTitle={ENV.COURSE.front_page_title}
            wikiUrl={ENV.COURSE.pages_url}
            returnFocusTo={this.chooseButton}
            isPublishing={false}
          />
        )}
      </div>
    )
  }

  onClick = () => {
    this.setState({dialogOpen: true})
  }

  onClose = () => {
    this.setState({dialogOpen: false})
  }
}

const addToDoSidebar = parent => {
  initializePlanner({
    env: window.ENV, // missing STUDENT_PLANNER_COURSES, which is what we want
    flashError: message => showFlashAlert({message, type: 'error'}),
    flashMessage: message => showFlashAlert({message, type: 'info'}),
    srFlashMessage: $.screenReaderFlashMessage,
    convertApiUserContent: apiUserContent.convert,
    dateTimeFormatters: {
      dateString: $.dateString,
      timeString: $.timeString,
      datetimeString: $.datetimeString
    },
    forCourse: ENV.COURSE.id
  })
  renderToDoSidebar(parent)
}

$(() => {
  $('#course_status_form').submit(e => {
    const input = e.target.elements.namedItem('course[event]')
    const value = input && input.value
    const courseId = ENV.COURSE.id
    if (value === 'offer') {
      e.preventDefault()

      const defaultView = defaultViewStore.getState().savedDefaultView
      const container = document.getElementById('choose_home_page_not_modules')
      if (container) {
        apiClient.getModules({courseId}).then(({data: modules}) => {
          if (defaultView === 'modules' && modules.length === 0) {
            ReactDOM.render(
              <HomePagePromptContainer
                forceOpen
                store={defaultViewStore}
                courseId={courseId}
                wikiFrontPageTitle={ENV.COURSE.front_page_title}
                wikiUrl={ENV.COURSE.pages_url}
                returnFocusTo={$('.btn-publish').get(0)}
                onSubmit={() => {
                  if (defaultViewStore.getState().savedDefaultView !== 'modules') {
                    apiClient.publishCourse({courseId})
                  }
                }}
              />,
              container
            )
          } else {
            apiClient.publishCourse({courseId})
          }
        })
      } else {
        // we don't have the ability to change to change the course home page so just publish it
        apiClient.publishCourse({courseId})
      }
    }
  })

  const container = document.getElementById('choose_home_page')
  if (container) {
    ReactDOM.render(<ChooseHomePageButton store={defaultViewStore} />, container)
  }

  const todo_container = document.querySelector('.todo-list')
  if (todo_container) {
    addToDoSidebar(todo_container)
  }
})
