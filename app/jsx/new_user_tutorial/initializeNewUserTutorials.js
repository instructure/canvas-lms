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
import axios from 'axios'
import NewUserTutorialToggleButton from './NewUserTutorialToggleButton'
import TutorialTray from './trays/TutorialTray'
import getProperTray from './utils/getProperTray'
import createTutorialStore from './utils/createTutorialStore'
import splitAssetString from 'compiled/str/splitAssetString'

const initializeNewUserTutorials = () => {
  if (
    window.ENV.NEW_USER_TUTORIALS &&
    window.ENV.NEW_USER_TUTORIALS.is_enabled &&
    (window.ENV.context_asset_string &&
      splitAssetString(window.ENV.context_asset_string)[0] === 'courses')
  ) {
    const API_URL = '/api/v1/users/self/new_user_tutorial_statuses'
    axios.get(API_URL).then(response => {
      let onPageToggleButton
      const trayObj = getProperTray()
      const collapsedStatus = response.data.new_user_tutorial_statuses.collapsed[trayObj.pageName]
      const store = createTutorialStore({
        isCollapsed: collapsedStatus
      })

      store.addChangeListener(() => {
        axios.put(`${API_URL}/${trayObj.pageName}`, {
          collapsed: store.getState().isCollapsed
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
          ref={c => {
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
