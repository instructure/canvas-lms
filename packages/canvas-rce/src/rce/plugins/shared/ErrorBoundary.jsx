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
import PropTypes from 'prop-types'
import formatMessage from '../../../format-message'

// TODO: a placeholder. Design a better one. See CORE-2826
export default class ErrorBoundary extends React.Component {
  static propTypes = {
    children: PropTypes.node,
  }

  constructor(props) {
    super(props)
    this.state = {hasError: false}
  }

  static getDerivedStateFromError(error) {
    // Update state so the next render will show the fallback UI.
    return {
      hasError: true,
      error,
    }
  }

  render() {
    if (this.state.hasError) {
      const msg = this.state.error.message ? this.state.error.message : this.state.error.toString()
      return (
        <div style={{margin: '1rem'}}>
          <h2>{formatMessage('Something went wrong.')}</h2>
          <p>{msg}</p>
        </div>
      )
    }
    return this.props.children
  }
}
