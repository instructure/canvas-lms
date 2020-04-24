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
import PropTypes from 'prop-types'
import I18n from 'i18n!dashcards'
import $ from 'jquery'

import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Button} from '@instructure/ui-buttons'
import HomePagePromptContainer from '../courses/HomePagePromptContainer'
import createStore from '../shared/helpers/createStore'
import * as apiClient from '../courses/apiClient'

export default class PublishButton extends React.Component {
  static propTypes = {
    defaultView: PropTypes.string.isRequired,
    pagesUrl: PropTypes.string.isRequired,
    courseId: PropTypes.string.isRequired,
    courseNickname: PropTypes.string.isRequired,
    frontPageTitle: PropTypes.string
  }

  static defaultProps = {
    frontPageTitle: ''
  }

  state = {
    showModal: false
  }

  componentDidMount() {
    const {defaultView} = this.props
    this.defaultViewStore = createStore({
      selectedDefaultView: defaultView,
      savedDefaultView: defaultView
    })
  }

  handleClose = () => {
    this.setState({showModal: false})
  }

  handleClick = () => {
    const {defaultView, courseId} = this.props
    if (defaultView === 'modules') {
      apiClient
        .getModules({courseId})
        .then(({data: modules}) => {
          if (modules.length === 0) {
            this.setState({showModal: true})
          } else {
            apiClient.publishCourse({courseId})
          }
        })
        .catch(() =>
          $.flashError(I18n.t('An error ocurred while fetching course details. Please try again.'))
        )
    } else {
      apiClient.publishCourse({courseId})
    }
  }

  render() {
    const {courseId, frontPageTitle, pagesUrl, courseNickname} = this.props
    const {showModal} = this.state

    return (
      <div className="ic-DashboardCard__header-publish">
        <Button onClick={this.handleClick} ref={b => (this.publishButton = b)} color="secondary">
          {I18n.t('Publish')}
          <ScreenReaderContent>{courseNickname}</ScreenReaderContent>
        </Button>
        {showModal && (
          <HomePagePromptContainer
            forceOpen
            store={this.defaultViewStore}
            courseId={courseId}
            wikiUrl={pagesUrl}
            wikiFrontPageTitle={frontPageTitle}
            onSubmit={() => {
              if (this.defaultViewStore.getState().savedDefaultView !== 'modules') {
                apiClient.publishCourse({courseId})
              }
            }}
            returnFocusTo={this.publishButton}
          />
        )}
      </div>
    )
  }
}
