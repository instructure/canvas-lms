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

import {Component, Children} from 'react'
import {shape, func, element} from 'prop-types'

const uiManagerShape = shape({
  handleAction: func.isRequired,
  registerAnimatable: func.isRequired,
  deregisterAnimatable: func.isRequired,
  preTriggerUpdates: func.isRequired,
  triggerUpdates: func.isRequired,
})

export class DynamicUiProvider extends Component {
  static propTypes = {
    manager: uiManagerShape.isRequired,
    children: element.isRequired,
  }

  static childContextTypes = {
    dynamicUiManager: uiManagerShape,
  }

  constructor(props, context) {
    super(props, context)
    this.manager = props.manager
  }

  getChildContext() {
    return {
      dynamicUiManager: this.manager,
    }
  }

  render() {
    return Children.only(this.props.children)
  }
}
