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
  // Because of how the original implementation was written this was the cleanest
  // way to get the values on the modal save button. A better solution would
  // require changing how the form button's actions are used to get the data from the
  // form.
  generateToolConfiguration = () => {
    return this.configMethodsRef.generateToolConfiguration();
  }

  valid = () => {
    return this.configMethodsRef.valid()
  }

  setConfigurationMethodsRef = node => this.configMethodsRef = node;

  body() {
    if (!this.props.createLtiKeyState.customizing) {
      return (
        <ToolConfigurationForm
          ref={this.setConfigurationMethodsRef}
          dispatch={this.props.dispatch}
          toolConfiguration={this.props.toolConfiguration}
          toolConfigurationUrl={this.props.createLtiKeyState.toolConfigurationUrl}
          validScopes={ENV.validLtiScopes}
          validPlacements={ENV.validLtiPlacements}
          setLtiConfigurationMethod={this.props.setLtiConfigurationMethod}
          configurationMethod={this.props.createLtiKeyState.configurationMethod}
          editing={this.props.editing}
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
        setPrivacyLevel={this.props.setPrivacyLevel}
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
  setLtiConfigurationMethod: PropTypes.func.isRequired,
  setPrivacyLevel: PropTypes.func.isRequired,
  createLtiKeyState: PropTypes.shape({
    customizing: PropTypes.bool.isRequired,
    toolConfiguration: PropTypes.object.isRequired,
    toolConfigurationUrl: PropTypes.string.isRequired,
    enabledScopes: PropTypes.arrayOf(PropTypes.string).isRequired,
    disabledPlacements: PropTypes.arrayOf(PropTypes.string).isRequired,
    configurationMethod: PropTypes.string.isRequired
  }).isRequired,
  toolConfiguration: PropTypes.shape({
    oidc_initiation_url: PropTypes.string
  }),
  editing: PropTypes.bool.isRequired
}
