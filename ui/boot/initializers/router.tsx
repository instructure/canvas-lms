/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import ReactDOM from 'react-dom'
import React from 'react'
import ready from '@instructure/ready'
import {BrowserRouter, Routes, Route} from 'react-router-dom'
import GroupNavigationSelectorRoute from '@canvas/group-navigation-selector/GroupNavigationSelectorRoute'
import ActAsModalRoute from '../../features/act_as_modal/react/ActAsModalRoute'

const App = () => {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/groups/:groupId/*" element={<GroupNavigationSelectorRoute />} />
        <Route path="/users/:userId/masquerade" element={<ActAsModalRoute />} />
      </Routes>
    </BrowserRouter>
  )
}

ready(() => {
  const mountNode = document.querySelector('#react-router')
  if (mountNode) {
    ReactDOM.render(<App />, mountNode)
  }
})
