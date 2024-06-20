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
import ObserverOptions from '@canvas/observer-picker'
import {
  getHandleChangeObservedUser,
  autoFocusObserverPicker,
} from '@canvas/observer-picker/util/pageReloadHelper'
import createStore from '@canvas/backbone/createStore'
import {View} from '@instructure/ui-view'
import $ from 'jquery'
import '@canvas/rails-flash-notifications'
import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import PropTypes from 'prop-types'
import ReactDOM from 'react-dom'
import {initializePlanner, renderToDoSidebar} from '@canvas/planner'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import apiUserContent from '@canvas/util/jquery/apiUserContent'
import * as apiClient from '@canvas/courses/courseAPIClient'
import {dateString, datetimeString, timeString} from '@canvas/datetime/date-functions'

const I18n = useI18nScope('courses_show')

const defaultViewStore = createStore({
  selectedDefaultView: ENV.COURSE.default_view,
  savedDefaultView: ENV.COURSE.default_view,
})

class ChooseHomePageButton extends React.Component {
  state = {
    dialogOpen: false,
  }

  static propTypes = {
    store: PropTypes.object.isRequired,
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
      dateString,
      timeString,
      datetimeString,
    },
    forCourse: ENV.COURSE.id,
  })
    .then(() => {
      renderToDoSidebar(parent)
    })
    .catch(() => {
      showFlashAlert({message: I18n.t('Failed to load the To Do Sidebar'), type: 'error'})
    })
}

$(() => {
  const container = document.getElementById('choose_home_page')
  if (container) {
    ReactDOM.render(<ChooseHomePageButton store={defaultViewStore} />, container)
  }

  const todo_container = document.querySelector('.todo-list')
  if (todo_container) {
    addToDoSidebar(todo_container)
  }

  const observerPickerContainer = document.getElementById('observer-picker-mountpoint')
  if (observerPickerContainer && ENV.OBSERVER_OPTIONS?.OBSERVED_USERS_LIST) {
    ReactDOM.render(
      <View as="div" maxWidth="12em">
        <ObserverOptions
          autoFocus={autoFocusObserverPicker()}
          canAddObservee={!!ENV.OBSERVER_OPTIONS?.CAN_ADD_OBSERVEE}
          currentUserRoles={ENV.current_user_roles}
          currentUser={ENV.current_user}
          handleChangeObservedUser={getHandleChangeObservedUser()}
          observedUsersList={ENV.OBSERVER_OPTIONS.OBSERVED_USERS_LIST}
          renderLabel={I18n.t('Select a student to view. The page will refresh automatically.')}
        />
      </View>,
      observerPickerContainer
    )
  }
})
