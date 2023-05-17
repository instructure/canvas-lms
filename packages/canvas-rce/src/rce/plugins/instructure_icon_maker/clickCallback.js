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

export const CREATE_ICON_MAKER = 'create_icon_maker_icon'
export const LIST_ICON_MAKER = 'list_icon_maker_icons'
export const EDIT_ICON_MAKER = 'edit_icon_maker_icon'

export const ICONS_TRAY_CONTAINER_ID = 'instructure-rce-icons-tray-container'

export default function (ed, document, type) {
  return import('./components/IconMakerTray').then(({IconMakerTray}) => {
    let container = document.querySelector(`#${ICONS_TRAY_CONTAINER_ID}`)
    const trayProps = bridge.trayProps.get(ed)

    const handleUnmount = () => {
      ReactDOM.unmountComponentAtNode(container)
      ed.focus(false)
    }

    if (!container) {
      container = document.createElement('div')
      container.id = ICONS_TRAY_CONTAINER_ID
      document.body.appendChild(container)
    } else if (type === CREATE_ICON_MAKER) {
      // This case indicates we are switching modes (i.e. Editing -> Creating)
      // We unmount the component to clear all state. This also triggers an animation
      // that closes and opens the tray to indicate a mode change to the user
      handleUnmount()
    }

    ReactDOM.render(
      <StoreProvider {...trayProps}>
        {() => (
          <IconMakerTray
            editor={ed}
            editing={type === EDIT_ICON_MAKER}
            onUnmount={handleUnmount}
            canvasOrigin={bridge.canvasOrigin}
          />
        )}
      </StoreProvider>,
      container
    )
  })
}
