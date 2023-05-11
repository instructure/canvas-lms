// @ts-nocheck
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
import {getProps} from './StudentColumnHeaderRenderer.utils'
import type Gradebook from '../../Gradebook'
import type GridSupport from '../GridSupport'

export default class StudentColumnHeaderRenderer {
  gradebook: Gradebook

  element: any

  columnName: string

  constructor(gradebook: Gradebook, element, columnName: string) {
    this.gradebook = gradebook
    this.element = element
    this.columnName = columnName
  }

  render(_column, $container: HTMLElement, _gridSupport: GridSupport, options) {
    const Element = this.element
    const props = getProps(this.gradebook, options, this.columnName)
    ReactDOM.render(<Element {...props} />, $container)
  }

  destroy(_column, $container: HTMLElement, _gridSupport: GridSupport) {
    ReactDOM.unmountComponentAtNode($container)
  }
}
