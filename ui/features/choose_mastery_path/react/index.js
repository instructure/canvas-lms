/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import {bindActionCreators} from 'redux'
import {connect, Provider} from 'react-redux'
import createStore from './store'
import actions from './actions'
import ChooseMasteryPath from './components/choose-mastery-path'

export default {
  init: (data, root) => {
    const options = data.options
    delete data.options

    const store = createStore(data)
    const boundActions = bindActionCreators(actions, store.dispatch)

    boundActions.setOptions(options)

    const ConnectedApp = connect(state => ({
      options: state.options,
      selectedOption: state.selectedOption,
    }))(ChooseMasteryPath)

    ReactDOM.render(
      <Provider store={store}>
        <ConnectedApp selectOption={boundActions.selectOption} />
      </Provider>,
      root
    )
  },
}
