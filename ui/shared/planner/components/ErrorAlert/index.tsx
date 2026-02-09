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
import React, {Component} from 'react'
import PropTypes from 'prop-types'
import {Alert} from '@instructure/ui-alerts'

export default class ErrorAlert extends Component {
  static propTypes = {
    error: PropTypes.oneOfType([PropTypes.string, PropTypes.instanceOf(Error)]),
    children: PropTypes.node.isRequired,
    margin: PropTypes.any,
  }

  static defaultProps = {
    error: null,
  }

  renderDetail() {
    // don't want to show the raw error to the user, but it might come in handy.
    // @ts-expect-error TS2339 (typescriptify)
    return this.props.error ? (
      <span style={{display: 'none'}}>
        {/* @ts-expect-error TS2339 (typescriptify) */}
        {this.props.error.message || this.props.error.toString()}
      </span>
    ) : null
  }

  render() {
    return (
      // @ts-expect-error TS2339 (typescriptify)
      <Alert variant="error" margin={this.props.margin || 'small'}>
        {/* @ts-expect-error TS2339 (typescriptify) */}
        {this.props.children}
        {this.renderDetail()}
      </Alert>
    )
  }
}
