/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import React from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'

import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Button} from '@instructure/ui-buttons'
import HomePagePromptContainer from '@canvas/course-homepage/react/Prompt'
import createStore from '@canvas/backbone/createStore'
import * as apiClient from '@canvas/courses/courseAPIClient'

const I18n = useI18nScope('dashcards')

type Props = {
  defaultView: string
  pagesUrl: string
  courseId: string
  courseNickname: string
  frontPageTitle: string
  onSuccess: () => void
}

export default class PublishButton extends React.Component<Props> {
  static defaultProps = {
    frontPageTitle: '',
    onSuccess: () => null,
  }

  defaultViewStore?: ReturnType<typeof createStore>

  publishButton: Element | null = null

  state = {
    showModal: false,
  }

  componentDidMount() {
    const {defaultView} = this.props
    this.defaultViewStore = createStore({
      selectedDefaultView: defaultView,
      savedDefaultView: defaultView,
    })
  }

  handleClose = () => {
    this.setState({showModal: false})
  }

  handleClick = () => {
    const {defaultView, courseId, onSuccess} = this.props
    if (defaultView === 'modules') {
      apiClient
        .getModules({courseId})
        .then(({data: modules}) => {
          if (modules.length === 0) {
            this.setState({showModal: true})
          } else {
            apiClient.publishCourse({courseId, onSuccess})
          }
        })
        .catch(() =>
          $.flashError(I18n.t('An error ocurred while fetching course details. Please try again.'))
        )
    } else {
      apiClient.publishCourse({courseId, onSuccess})
    }
  }

  render() {
    const {courseId, frontPageTitle, pagesUrl, courseNickname, onSuccess} = this.props
    const {showModal} = this.state

    return (
      <div className="ic-DashboardCard__header-publish">
        <Button
          onClick={this.handleClick}
          elementRef={(b: Element | null) => (this.publishButton = b)}
          color="secondary"
        >
          {I18n.t('Publish')}
          <ScreenReaderContent>{courseNickname}</ScreenReaderContent>
        </Button>
        {showModal && (
          <HomePagePromptContainer
            forceOpen={true}
            store={this.defaultViewStore}
            courseId={courseId}
            wikiUrl={pagesUrl}
            wikiFrontPageTitle={frontPageTitle}
            onSubmit={() => {
              // @ts-expect-error
              if (this.defaultViewStore?.getState().savedDefaultView !== 'modules') {
                apiClient.publishCourse({courseId, onSuccess})
              }
            }}
            returnFocusTo={this.publishButton}
          />
        )}
      </div>
    )
  }
}
