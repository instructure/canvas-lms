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
import I18n from 'i18n!react_developer_keys'
import PropTypes from 'prop-types'
import React from 'react'

import Heading from '@instructure/ui-elements/lib/components/Heading'
import Select from '@instructure/ui-forms/lib/components/Select'
import TextArea from '@instructure/ui-forms/lib/components/TextArea'
import TextInput from '@instructure/ui-forms/lib/components/TextInput'
import View from '@instructure/ui-layout/lib/components/View'

import ManualConfigurationForm from './ManualConfigurationForm'

export default class ToolConfigurationForm extends React.Component {
  get toolConfiguration() {
    const {toolConfiguration} = this.props
    return toolConfiguration ? JSON.stringify(toolConfiguration, null, 4) : ''
  }

  generateToolConfiguration = () => {
    return this.manualConfigRef.generateToolConfiguration();
  }

  valid = () => {
    return this.manualConfigRef.valid();
  }

  handleConfigTypeChange = (e, option) => {
    this.props.dispatch(this.props.setLtiConfigurationMethod(option.value))
  }

  setManualConfigRef = node => this.manualConfigRef = node;

  configurationInput() {
    if (this.props.configurationMethod === 'json') {
      return (
        <TextArea
          name="tool_configuration"
          defaultValue={this.toolConfiguration}
          label={I18n.t('LTI 1.3 Configuration')}
          maxHeight="20rem"
        />
      )
    } else if (this.props.configurationMethod === 'manual') {
      return (
        <ManualConfigurationForm
          ref={this.setManualConfigRef}
          toolConfiguration={this.props.toolConfiguration}
          validScopes={this.props.validScopes}
          validPlacements={this.props.validPlacements}
        />
      )
    }
    return (
      <TextInput
        name="tool_configuration_url"
        defaultValue={this.props.toolConfigurationUrl}
        label={I18n.t('JSON URL')}
      />
    )
  }

  renderOptions () {
    return [
      <option key="manual" value="manual">{I18n.t('Manual Entry')}</option>,
      <option key="json" value="json">{I18n.t('Paste JSON')}</option>,
      this.props.editing ? null : <option key="url" value="url">{I18n.t('Enter URL')}</option>
    ].filter(o => !!o)
  }

  render() {
    return (
      <View>
        <Heading level="h2" as="h2" margin="0 0 x-small">
          {I18n.t('Configure')}
        </Heading>
        <Select
          label="Method"
          assistiveText={I18n.t('3 options available. Use arrow keys to navigate options.')}
          onChange={this.handleConfigTypeChange}
          selectedOption={this.props.configurationMethod}
        >
          {this.renderOptions()}
        </Select>
        <br />
        {this.configurationInput()}
      </View>
    )
  }
}

ToolConfigurationForm.propTypes = {
  dispatch: PropTypes.func.isRequired,
  toolConfiguration: PropTypes.object.isRequired,
  toolConfigurationUrl: PropTypes.string.isRequired,
  validScopes: PropTypes.object.isRequired,
  validPlacements: PropTypes.arrayOf(PropTypes.string).isRequired,
  setLtiConfigurationMethod: PropTypes.func.isRequired,
  configurationMethod: PropTypes.string,
  editing: PropTypes.bool.isRequired
}

ToolConfigurationForm.defaultProps = {
  configurationMethod: 'json'
}
