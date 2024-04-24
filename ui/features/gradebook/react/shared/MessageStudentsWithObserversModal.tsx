// @ts-nocheck
/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import AsyncComponents from '../default_gradebook/AsyncComponents'
import {ApolloProvider} from 'react-apollo'
import {createClient} from '@canvas/apollo'

export const showMessageStudentsWithObserversModal = async (props, focusAtEnd) => {
  const mountPoint = document.querySelector("[data-component='MessageStudentsWithObserversModal']")
  if (mountPoint !== null) {
    const dialogeProps = {
      ...props,
      onClose: () => {
        ReactDOM.unmountComponentAtNode(mountPoint)
        focusAtEnd()
      },
    }
    const MessageStudentsWhoDialog = await AsyncComponents.loadMessageStudentsWithObserversDialog()

    ReactDOM.render(
      <ApolloProvider client={createClient()}>
        <MessageStudentsWhoDialog {...dialogeProps} />
      </ApolloProvider>,
      mountPoint
    )
  }
}
