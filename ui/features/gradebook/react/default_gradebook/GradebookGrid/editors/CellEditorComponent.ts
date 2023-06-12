// @ts-nocheck
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

import {PureComponent} from 'react'

export default class CellEditorComponent extends PureComponent {
  constructor(props) {
    super(props)

    this.applyValue = this.applyValue.bind(this)
    this.focus = this.focus.bind(this)
    this.handleKeyDown = this.handleKeyDown.bind(this)
    this.isValueChanged = this.isValueChanged.bind(this)
  }

  /*
   * ReactCellEditor Interface Method (required)
   */
  applyValue() {}

  /*
   * ReactCellEditor Interface Method (required)
   */
  focus() {}

  /*
   * ReactCellEditor Interface Method (required)
   */
  handleKeyDown(/* event */) {
    return undefined
  }

  /*
   * ReactCellEditor Interface Method (required)
   */
  isValueChanged() {
    return false
  }
}
