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

import {Heading} from '@instructure/ui-heading'
// If we want to upgrade this Select to the new Inst UI Select in ui-select,
// which is not backwards-compatible, we can use CanvasSelect.
import {Select} from '@instructure/ui-forms'
import {TextArea} from '@instructure/ui-text-area'
import {TextInput} from '@instructure/ui-text-input'
import {Grid} from '@instructure/ui-grid'
import {View} from '@instructure/ui-view'

import ManualConfigurationForm from './ManualConfigurationForm'

const validationMessageInvalidJson = [
  {text: I18n.t('Json is not valid. Please submit properly formatted json.'), type: 'error'}
]
const validationMessageRequiredField = [{text: I18n.t('Field cannot be blank.'), type: 'error'}]

export default class ToolConfigurationForm extends React.Component {
  state = {
    invalidJson: null
  }

  get toolConfiguration() {
    if (this.state.invalidJson) {
      return this.state.invalidJson
    }
    const {toolConfiguration} = this.props
    return toolConfiguration ? JSON.stringify(toolConfiguration, null, 4) : ''
  }

  generateToolConfiguration = () => {
    return this.manualConfigRef.generateToolConfiguration()
  }

  valid = () => {
    return this.manualConfigRef.valid()
  }

  updatePastedJson = value => {
    try {
      const settings = JSON.parse(value.target.value)
      this.props.updateToolConfiguration(settings)
      this.setState({invalidJson: null})
    } catch (e) {
      if (e instanceof SyntaxError) {
        this.setState({invalidJson: value.target.value})
      }
    }
  }

  updateToolConfigurationUrl = e => {
    this.props.updateToolConfigurationUrl(e.target.value)
  }

  handleConfigTypeChange = (e, option) => {
    this.props.updateConfigurationMethod(option.value)
  }

  setManualConfigRef = node => (this.manualConfigRef = node)

  configurationInput() {
    const {configurationMethod} = this.props
    if (configurationMethod === 'json') {
      return (
        <TextArea
          name="tool_configuration"
          value={this.toolConfiguration}
          onChange={this.updatePastedJson}
          label={I18n.t('LTI 1.3 Configuration')}
          maxHeight="20rem"
          messages={
            this.props.showRequiredMessages && this.state.invalidJson
              ? validationMessageInvalidJson
              : []
          }
        />
      )
    } else if (configurationMethod === 'manual') {
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
        value={this.props.toolConfigurationUrl}
        onChange={this.updateToolConfigurationUrl}
        label={I18n.t('JSON URL')}
        messages={this.props.showRequiredMessages ? validationMessageRequiredField : []}
      />
    )
  }

  renderOptions() {
    return [
      <option key="manual" value="manual">
        {I18n.t('Manual Entry')}
      </option>,
      <option key="json" value="json">
        {I18n.t('Paste JSON')}
      </option>,
      this.props.editing ? null : (
        <option key="url" value="url">
          {I18n.t('Enter URL')}
        </option>
      )
    ].filter(o => !!o)
  }

  renderBody() {
    return (
      <View>
        <Heading level="h2" as="h2" margin="0 0 x-small">
          {I18n.t('Configure')}
        </Heading>
        <Select
          label="Method"
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

  render() {
    return (
      <Grid.Row>
        <Grid.Col>{this.renderBody()}</Grid.Col>
      </Grid.Row>
    )
  }
}

ToolConfigurationForm.propTypes = {
  toolConfiguration: PropTypes.object.isRequired,
  toolConfigurationUrl: PropTypes.string.isRequired,
  validScopes: PropTypes.object.isRequired,
  validPlacements: PropTypes.arrayOf(PropTypes.string).isRequired,
  editing: PropTypes.bool.isRequired,
  showRequiredMessages: PropTypes.bool.isRequired,
  updateToolConfiguration: PropTypes.func.isRequired,
  updateToolConfigurationUrl: PropTypes.func.isRequired,
  configurationMethod: PropTypes.string.isRequired,
  updateConfigurationMethod: PropTypes.func.isRequired
}
