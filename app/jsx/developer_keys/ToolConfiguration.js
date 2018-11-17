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
import CustomizationForm from './CustomizationForm'
import ToolConfigurationForm from './ToolConfigurationForm'

export default class ToolConfiguration extends React.Component {
  body() {
    if (!this.props.createLtiKeyState.customizing) {
      return (
        <ToolConfigurationForm
          toolConfiguration={this.props.createLtiKeyState.toolConfiguration}
          toolConfigurationUrl={this.props.createLtiKeyState.toolConfigurationUrl}
        />
      )
    }
    return (
      <CustomizationForm
        toolConfiguration={this.props.createLtiKeyState.toolConfiguration}
        validScopes={ENV.validLtiScopes}
        validPlacements={ENV.validLtiPlacements}
        enabledScopes={this.props.createLtiKeyState.enabledScopes}
        disabledPlacements={this.props.createLtiKeyState.disabledPlacements}
        dispatch={this.props.dispatch}
        setEnabledScopes={this.props.setEnabledScopes}
        setDisabledPlacements={this.props.setDisabledPlacements}
      />
    )
  }

  render() {
    return (
      <GridRow>
        <GridCol>{this.body()}</GridCol>
      </GridRow>
    )
  }
}

ToolConfiguration.propTypes = {
  dispatch: PropTypes.func.isRequired,
  setEnabledScopes: PropTypes.func.isRequired,
  setDisabledPlacements: PropTypes.func.isRequired,
  createLtiKeyState: PropTypes.shape({
    customizing: PropTypes.bool.isRequired,
    toolConfiguration: PropTypes.object.isRequired,
    toolConfigurationUrl: PropTypes.string.isRequired,
    enabledScopes: PropTypes.arrayOf(PropTypes.string).isRequired,
    disabledPlacements: PropTypes.arrayOf(PropTypes.string).isRequired,
  }).isRequired
}
