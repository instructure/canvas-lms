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

import React from 'react'
import ReactDOM from 'react-dom'
import {Pill} from '@instructure/ui-pill'
import type {PillProps} from '@instructure/ui-pill'

export const renderFrontPagePill = (el: HTMLElement, props?: PillProps) => {
  const frontPageContainer = el.querySelector('.front-page')
  let children
  if (typeof props !== 'undefined') {
    children = props.children
    delete props.children
  }
  if (frontPageContainer) {
    ReactDOM.render(<Pill {...props}>{children}</Pill>, frontPageContainer)
  }

  return <Pill {...props}>{children}</Pill>
}
