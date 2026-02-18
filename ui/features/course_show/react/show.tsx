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
import ObserverOptions from '@canvas/observer-picker'
import {
  getHandleChangeObservedUser,
  autoFocusObserverPicker,
} from '@canvas/observer-picker/util/pageReloadHelper'
import createStore from '@canvas/backbone/createStore'
import {View} from '@instructure/ui-view'
import $ from 'jquery'
import '@canvas/rails-flash-notifications'
import {useScope as createI18nScope} from '@canvas/i18n'
import React from 'react'
import {legacyRender, render} from '@canvas/react'
import {initializePlanner, renderToDoSidebar} from '@canvas/planner'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import apiUserContent from '@canvas/util/jquery/apiUserContent'
import {dateString, datetimeString, timeString} from '@canvas/datetime/date-functions'
import CourseDifferentiationTagConverterMessage from '@canvas/differentiation-tags/react/DifferentiationTagConverterMessage/course-conversion/CourseDifferentiationTagConverterMessage'

const I18n = createI18nScope('courses_show')

interface DefaultViewStore {
  selectedDefaultView: string
  savedDefaultView: string
}

// @ts-expect-error - Canvas ENV global not fully typed
const defaultViewStore: DefaultViewStore = createStore({
  selectedDefaultView: ENV.COURSE?.default_view,
  savedDefaultView: ENV.COURSE?.default_view,
})

interface ChooseHomePageButtonProps {
  store: DefaultViewStore
}

interface ChooseHomePageButtonState {
  dialogOpen: boolean
}

class ChooseHomePageButton extends React.Component<
  ChooseHomePageButtonProps,
  ChooseHomePageButtonState
> {
  state: ChooseHomePageButtonState = {
    dialogOpen: false,
  }

  chooseButton: HTMLButtonElement | null = null

  render(): React.JSX.Element {
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
            // @ts-expect-error - Canvas ENV global not fully typed
            courseId={ENV.COURSE.id}
            // @ts-expect-error - Canvas ENV global not fully typed
            wikiFrontPageTitle={ENV.COURSE.front_page_title}
            // @ts-expect-error - Canvas ENV global not fully typed
            wikiUrl={ENV.COURSE.pages_url}
            returnFocusTo={this.chooseButton}
            isPublishing={false}
          />
        )}
      </div>
    )
  }

  onClick = (): void => {
    this.setState({dialogOpen: true})
  }

  onClose = (): void => {
    this.setState({dialogOpen: false})
  }
}

const addToDoSidebar = (parent: Element): void => {
  initializePlanner({
    env: window.ENV, // missing STUDENT_PLANNER_COURSES, which is what we want
    flashError: (message: string) => showFlashAlert({message, type: 'error'}),
    flashMessage: (message: string) => showFlashAlert({message, type: 'info'}),
    srFlashMessage: $.screenReaderFlashMessage,
    convertApiUserContent: apiUserContent.convert,
    dateTimeFormatters: {
      dateString,
      timeString,
      datetimeString,
    },
    forCourse: ENV.COURSE?.id,
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
    legacyRender(<ChooseHomePageButton store={defaultViewStore} />, container)
  }

  const todo_container = document.querySelector('.todo-list')
  if (todo_container) {
    addToDoSidebar(todo_container)
  }

  const observerPickerContainer = document.getElementById('observer-picker-mountpoint')
  if (observerPickerContainer && ENV.OBSERVER_OPTIONS?.OBSERVED_USERS_LIST) {
    legacyRender(
      <View as="div" maxWidth="12em">
        <ObserverOptions
          // eslint-disable-next-line jsx-a11y/no-autofocus
          autoFocus={autoFocusObserverPicker()}
          canAddObservee={!!ENV.OBSERVER_OPTIONS?.CAN_ADD_OBSERVEE}
          currentUserRoles={ENV.current_user_roles}
          currentUser={ENV.current_user}
          handleChangeObservedUser={getHandleChangeObservedUser()}
          observedUsersList={ENV.OBSERVER_OPTIONS.OBSERVED_USERS_LIST}
          renderLabel={I18n.t('Select a student to view. The page will refresh automatically.')}
        />
      </View>,
      observerPickerContainer,
    )
  }

  const diffTagOverrideConversionContainer = document.getElementById(
    'differentiation-tag-converter-message-root',
  )
  if (diffTagOverrideConversionContainer) {
    render(
      <CourseDifferentiationTagConverterMessage
        courseId={ENV.COURSE?.id || ''}
        // @ts-expect-error - ACTIVE_TAG_CONVERSION_JOB not in ENV type
        activeConversionJob={ENV.ACTIVE_TAG_CONVERSION_JOB}
      />,
      diffTagOverrideConversionContainer,
    )
  }
})
