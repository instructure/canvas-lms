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
import PropTypes from 'prop-types'

type ErrorBoundaryState = {
  hasError: boolean
}

class ErrorBoundary extends React.Component {
  static propTypes = {
    children: PropTypes.node,
  }

  state: ErrorBoundaryState

  constructor(props) {
    super(props)
    this.state = {hasError: false}
  }

  static getDerivedStateFromError(error) {
    // Update state so the next render will show the fallback UI.
    return {
      hasError: true,
    }
  }

  componentDidCatch(error, info) {
    // eslint-disable-next-line no-console
    console.error(error, '\n', info.componentStack)
  }

  render() {
    if (this.state.hasError) {
      return (
        <div style={{margin: '1rem'}}>
          <h2>Something went wrong.</h2>
        </div>
      )
    }
    return this.props.children
  }
}

export {ErrorBoundary}
