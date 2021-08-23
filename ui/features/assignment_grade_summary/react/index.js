/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import React, {Component} from 'react'
import {Provider} from 'react-redux'

import Layout from './components/Layout'
import configureStore from './configureStore'
import getEnv from './getEnv'

export default class GradeSummary extends Component {
  constructor(props) {
    super(props)

    this.store = configureStore(getEnv())
  }

  render() {
    return (
      <Provider store={this.store}>
        <Layout />
      </Provider>
    )
  }
}
