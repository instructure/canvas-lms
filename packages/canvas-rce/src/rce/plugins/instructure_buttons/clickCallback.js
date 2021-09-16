/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import bridge from '../../../bridge'
import {StoreProvider} from '../shared/StoreContext'

export const CREATE_BUTTON = 'create_buttons_and_icons'
export const LIST_BUTTON = 'list_buttons_and_icons'
export const EDIT_BUTTON = 'edit_buttons_and_icons'

export default function (ed, document, type) {
  return import('./components/ButtonsTray').then(({ButtonsTray}) => {
    let container = document.querySelector('#instructure-rce-buttons-tray-container')
    const trayProps = bridge.trayProps.get(ed)

    if (!container) {
      container = document.createElement('div')
      container.id = 'instructure-rce-buttons-tray-container'
      document.body.appendChild(container)
    }

    const handleUnmount = () => {
      ReactDOM.unmountComponentAtNode(container)
      ed.focus(false)
    }

    ReactDOM.render(
      <StoreProvider {...trayProps}>
        {() => <ButtonsTray editor={ed} editing={type === EDIT_BUTTON} onUnmount={handleUnmount} />}
      </StoreProvider>,
      container
    )
  })
}
