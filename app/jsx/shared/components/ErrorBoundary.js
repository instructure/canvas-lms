/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {node} from 'prop-types'

export default class ErrorBoundary extends React.Component {
  static propTypes = {
    children: node.isRequired,
    errorComponent: node.isRequired
  }

  static getDerivedStateFromError(error) {
    return {hasError: true, error}
  }

  componentDidCatch(error, errorInfo) {
    console.error(error, errorInfo)
  }

  state = {hasError: false, error: null}

  render() {
    if (this.state.hasError) {
      return React.cloneElement(this.props.errorComponent, {errorSubject: this.state.error.message})
    }

    return this.props.children
  }
}
