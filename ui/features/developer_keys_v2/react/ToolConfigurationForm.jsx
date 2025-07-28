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
import {useScope as createI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React, {createRef} from 'react'

import {Heading} from '@instructure/ui-heading'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {TextArea} from '@instructure/ui-text-area'
import {TextInput} from '@instructure/ui-text-input'
import {Grid} from '@instructure/ui-grid'
import {View} from '@instructure/ui-view'
import {Button} from '@instructure/ui-buttons'

import ManualConfigurationForm from './ManualConfigurationForm/index'

const I18n = createI18nScope('react_developer_keys')

const validationMessage = {
  text: [{text: I18n.t('Field cannot be blank.'), type: 'error'}],
  url: [{text: I18n.t('Please enter a valid URL (e.g. https://example.com)'), type: 'error'}],
  json: [
    {text: I18n.t('Json is not valid. Please submit properly formatted json.'), type: 'error'},
  ],
}

export default class ToolConfigurationForm extends React.Component {
  state = {
    isUrlValid: true,
    jsonUrl: this.props.toolConfigurationUrl || '',
    showMessages: false,
  }

  get toolConfiguration() {
    if (this.props.invalidJson !== null && this.props.invalidJson !== undefined) {
      return this.props.invalidJson
    }
    if (this.props.jsonString) {
      return this.props.jsonString
    }
    const {toolConfiguration} = this.props
    return toolConfiguration ? JSON.stringify(toolConfiguration, null, 4) : ''
  }

  generateToolConfiguration = () => {
    return this.manualConfigRef.generateToolConfiguration()
  }

  jsonRef = createRef()
  urlRef = createRef()

  validateUrlField = (fieldValue, fieldStateKey, fieldRef) => {
    if (!fieldValue || (fieldValue && !URL.canParse(fieldValue))) {
      this.setState({[fieldStateKey]: false})
      if (this.isValid) {
        fieldRef.current.focus()
        this.isValid = false
      }
    } else {
      this.setState({[fieldStateKey]: true})
    }
  }

  valid = () => {
    this.isValid = true

    if (this.isManual()) {
      return this.manualConfigRef.valid()
    } else if (this.isJson()) {
      if (this.props.invalidJson || this.toolConfiguration === '{}') {
        this.jsonRef.current.focus()
        this.isValid = false
        this.setState({showMessages: true})
      }
    } else if (this.isUrl()) {
      this.validateUrlField(this.state.jsonUrl, 'isUrlValid', this.urlRef)
    }

    return this.isValid
  }

  isManual = () => {
    return this.props.configurationMethod === 'manual'
  }

  isJson = () => {
    return this.props.configurationMethod === 'json'
  }

  isUrl = () => {
    return this.props.configurationMethod === 'url'
  }

  updatePastedJson = e => {
    this.props.updatePastedJson(e.target.value, e.target.selectionEnd === e.target.value.length)
  }

  handleJsonChange = e => {
    try {
      JSON.parse(e.target.value)
      this.setState({showMessages: false})
      this.updatePastedJson(e)
    } catch (error) {
      if (error instanceof SyntaxError) {
        this.setState({showMessages: true})
        this.updatePastedJson(e)
      }
    }
  }

  handleToolConfigUrlChange = e => {
    const value = e.target.value
    this.setState({jsonUrl: value})
    this.validateUrlField(value, 'isUrlValid', this.urlRef)
    this.props.updateToolConfigurationUrl(value)
  }

  handleConfigTypeChange = (e, option) => {
    this.props.updateConfigurationMethod(option.value)
    if (option.value === 'json') {
      this.props.updatePastedJson(this.toolConfiguration, true)
    }
  }

  setManualConfigRef = node => (this.manualConfigRef = node)

  jsonConfigurationInput = () => (
    <Grid>
      <Grid.Row>
        <Grid.Col>
          <TextArea
            name="tool_configuration"
            value={this.toolConfiguration}
            onChange={this.handleJsonChange}
            label={I18n.t('LTI 1.3 Configuration')}
            textareaRef={ref => {
              this.jsonRef.current = ref
            }}
            maxHeight="20rem"
            required={this.props.configurationMethod === 'json'}
            messages={this.state.showMessages ? validationMessage.json : []}
          />
        </Grid.Col>
      </Grid.Row>
      <Grid.Row>
        <Grid.Col>
          <Button
            onClick={this.props.prettifyPastedJson}
            interaction={this.props.canPrettify ? 'enabled' : 'disabled'}
          >
            {I18n.t('Prettify JSON')}
          </Button>
        </Grid.Col>
      </Grid.Row>
    </Grid>
  )

  urlConfigurationInput = () => (
    <TextInput
      name="tool_configuration_url"
      value={this.state.jsonUrl}
      isRequired={this.props.configurationMethod === 'url'}
      inputRef={ref => {
        this.urlRef.current = ref
      }}
      onChange={this.handleToolConfigUrlChange}
      renderLabel={I18n.t('JSON URL')}
      messages={
        this.props.showRequiredMessages && !this.state.isUrlValid ? validationMessage.url : []
      }
    />
  )

  manualConfigurationInput = visible => (
    <div style={{display: visible ? undefined : 'none'}}>
      <ManualConfigurationForm
        ref={this.setManualConfigRef}
        toolConfiguration={this.props.toolConfiguration}
        validScopes={this.props.validScopes}
        validPlacements={this.props.validPlacements}
      />
    </div>
  )

  renderOptions() {
    return [
      <SimpleSelect.Option id="manual" key="manual" value="manual">
        {I18n.t('Manual Entry')}
      </SimpleSelect.Option>,
      <SimpleSelect.Option id="json" key="json" value="json">
        {I18n.t('Paste JSON')}
      </SimpleSelect.Option>,
      this.props.editing ? null : (
        <SimpleSelect.Option id="url" key="url" value="url">
          {I18n.t('Enter URL')}
        </SimpleSelect.Option>
      ),
    ].filter(o => o !== null)
  }

  renderBody() {
    const {configurationMethod} = this.props

    return (
      <View>
        <Heading level="h2" as="h2" margin="0 0 x-small">
          {I18n.t('Configure')}
        </Heading>
        <SimpleSelect
          renderLabel={I18n.t('Method')}
          onChange={this.handleConfigTypeChange}
          value={this.props.configurationMethod}
        >
          {this.renderOptions()}
        </SimpleSelect>
        <br />
        {configurationMethod === 'json' && this.jsonConfigurationInput()}
        {configurationMethod === 'url' && this.urlConfigurationInput()}
        {
          this.manualConfigurationInput(
            configurationMethod === 'manual',
          ) /* show invisible to preserve state */
        }
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
  toolConfigurationUrl: PropTypes.string,
  validScopes: PropTypes.object.isRequired,
  validPlacements: PropTypes.arrayOf(PropTypes.string).isRequired,
  editing: PropTypes.bool.isRequired,
  showRequiredMessages: PropTypes.bool.isRequired,
  updateToolConfigurationUrl: PropTypes.func.isRequired,
  configurationMethod: PropTypes.string.isRequired,
  updateConfigurationMethod: PropTypes.func.isRequired,
  prettifyPastedJson: PropTypes.func.isRequired,
  invalidJson: PropTypes.string,
  jsonString: PropTypes.string,
  updatePastedJson: PropTypes.func,
  canPrettify: PropTypes.bool,
}
