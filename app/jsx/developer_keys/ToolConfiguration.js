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

import {GridCol, GridRow} from '@instructure/ui-layout/lib/components/Grid'
import ToolConfigurationForm from './ToolConfigurationForm'

export default class ToolConfiguration extends React.Component {
  body() {
    if (!this.props.customizing) {
      return (
        <ToolConfigurationForm
          toolConfiguration={this.props.toolConfiguration}
          configurationUrl={this.props.configurationUrl}
        />
      )
    }
  }

  render() {
    return (
      <GridRow>
        <GridCol>{this.body()}</GridCol>
      </GridRow>
    )
  }
}

ToolConfiguration.defaultProps = {
  toolConfiguration: undefined,
  configurationUrl: undefined
}

ToolConfiguration.propTypes = {
  customizing: PropTypes.bool.isRequired,
  toolConfiguration: PropTypes.object,
  configurationUrl: PropTypes.string
}
