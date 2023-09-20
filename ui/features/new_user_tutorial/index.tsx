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

import React from 'react'
import ReactDOM from 'react-dom'
import axios from '@canvas/axios'
import NewUserTutorialToggleButton from './react/NewUserTutorialToggleButton'
import TutorialTray from './react/trays/TutorialTray'
import getProperTray from './react/util/getProperTray'
import createTutorialStore from './react/util/createTutorialStore'
import splitAssetString from '@canvas/util/splitAssetString'

const initializeNewUserTutorials = () => {
  if (
    window.ENV.NEW_USER_TUTORIALS &&
    window.ENV.NEW_USER_TUTORIALS.is_enabled &&
    window.ENV.context_asset_string &&
    splitAssetString(window.ENV.context_asset_string)?.[0] === 'courses'
  ) {
    const API_URL = '/api/v1/users/self/new_user_tutorial_statuses'
    return axios.get(API_URL).then(response => {
      let onPageToggleButton: NewUserTutorialToggleButton | null = null
      const trayObj = getProperTray()
      if (!trayObj) {
        throw new Error('No tray found')
      }
      const collapsedStatus = response.data.new_user_tutorial_statuses.collapsed[trayObj.pageName]
      const store = createTutorialStore({
        isCollapsed: collapsedStatus,
      })

      store.addChangeListener(() => {
        axios.put(`${API_URL}/${trayObj.pageName}`, {
          collapsed: store.getState().isCollapsed,
        })
      })

      const getReturnFocus = () => onPageToggleButton

      const renderTray = () => {
        const Tray = trayObj.component
        ReactDOM.render(
          <TutorialTray store={store} returnFocusToFunc={getReturnFocus} label={trayObj.label}>
            <Tray />
          </TutorialTray>,
          document.querySelector('.NewUserTutorialTray__Container')
        )
      }
      ReactDOM.render(
        <NewUserTutorialToggleButton
          ref={(c: NewUserTutorialToggleButton | null) => {
            onPageToggleButton = c
          }}
          store={store}
        />,
        document.querySelector('.TutorialToggleHolder'),
        () => renderTray()
      )
    })
  }
}

export default initializeNewUserTutorials
