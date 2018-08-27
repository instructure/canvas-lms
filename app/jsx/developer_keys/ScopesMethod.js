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
import PropTypes from 'prop-types'
import React from 'react'
import Pill from '@instructure/ui-elements/lib/components/Pill'

export default class ScopesMethod extends React.Component {
  methodColorMap() {
    return({
      get: 'primary',
      put: 'default',
      post: 'success',
      delete: 'danger'
    })
  }

  themeOverride() {
    return({
      color: '#6D7883'
    })
  }

  render() {
    return (
      <Pill
        data-automation="developer-key-scope-pill"
        text={this.props.method}
        variant={this.methodColorMap()[this.props.method.toLowerCase()]}
        margin={this.props.margin}
        color="#6D7883"
        theme={this.themeOverride()}
      />
    )
  }
}

ScopesMethod.propTypes = {
  method: PropTypes.string.isRequired,
  margin: PropTypes.string
}

ScopesMethod.defaultProps = {
  margin: undefined
}
