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

import React, {createRef} from 'react'
import {render, unmountComponentAtNode} from 'react-dom'
import RCEWrapper from './RCEWrapper'
import normalizeProps from './normalizeProps'
import formatMessage from '../format-message'

if (!process || !process.env || !process.env.BUILD_LOCALE) {
  formatMessage.setup({
    locale: 'en',
    generateId: require('format-message-generate-id/underscored_crc32'),
    missingTranslation: 'ignore',
  })
}

export function renderIntoDiv(target, props, renderCallback) {
  import('./tinyRCE')
    .then(module => {
      const tinyRCE = module.default

      // normalize props
      props = normalizeProps(props, tinyRCE)

      formatMessage.setup({locale: props.language})
      // render the editor to the target element
      const renderedComponent = createRef()
      render(
        <RCEWrapper
          ref={renderedComponent}
          {...props}
          handleUnmount={() => unmountComponentAtNode(target)}
        />,
        target,
        () => {
          // pass it back
          renderCallback && renderCallback(renderedComponent.current)
        }
      )
    })
    .catch(err => {
      // eslint-disable-next-line no-console
      console.error('Failed loading RCE', err)
    })
}

// Adding this event listener fixes LA-212. I have no idea why. In Safari it
// lets the user scroll the iframe via the mouse wheel without having to resize
// the RCE or the window or something else first.
if (window) window.addEventListener('wheel', () => {})
