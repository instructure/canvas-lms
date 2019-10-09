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
import invert from 'lodash/invert'
import I18n from 'i18n!react_developer_keys'
import PropTypes from 'prop-types'
import React from 'react'
import {Heading} from '@instructure/ui-elements'
import {TextArea} from '@instructure/ui-forms'
import {View} from '@instructure/ui-layout'
import CustomizationTable from './CustomizationTable'
import OtherOptions from './OtherOptions'

export const customFieldsStringToObject = (data) => {
  const output = {}
  data.split('\n').forEach(field => {
    const value = field.split('=')
    if(value.length > 1) {
      output[value[0]] = value[1]
    }
  })
  return output
}

export const objectToCustomVariablesString = (custom_fields) => {
  if(!custom_fields || Object.keys(custom_fields).length === 0) { return '' }
  return Object.keys(custom_fields).map(
    k => `${k}=${custom_fields[k]}`
  ).join('\n')
}

const validationMessage = [{text: I18n.t('Invalid custom fields.'), type: 'error'}]

export default class CustomizationForm extends React.Component {
  static propTypes = {
    toolConfiguration: PropTypes.object.isRequired,
    validScopes: PropTypes.object.isRequired,
    validPlacements: PropTypes.arrayOf(PropTypes.string).isRequired,
    enabledScopes: PropTypes.arrayOf(PropTypes.string).isRequired,
    disabledPlacements: PropTypes.arrayOf(PropTypes.string).isRequired,
    dispatch: PropTypes.func.isRequired,
    setEnabledScopes: PropTypes.func.isRequired,
    setDisabledPlacements: PropTypes.func.isRequired,
    setPrivacyLevel: PropTypes.func.isRequired,
    updateToolConfiguration: PropTypes.func.isRequired,
    showCustomizationMessages: PropTypes.bool
  }

  constructor(props) {
    super(props)
    const {dispatch, setPrivacyLevel} = this.props
    this.invertedScopes = invert(this.props.validScopes)
    dispatch(setPrivacyLevel(this.privacyLevel))
    this.state = {
      custom_fields: objectToCustomVariablesString(props.toolConfiguration.custom_fields),
      valid: true
    }
  }

  get privacyLevel() {
    const extension = this.canvasExtension
    return extension && extension.privacy_level === 'public' ? extension.privacy_level : 'anonymous'
  }

  get scopes() {
    const {toolConfiguration, validScopes} = this.props
    const validScopeNames = Object.keys(validScopes)

    if (!toolConfiguration.scopes) {
      return []
    }

    // Intersection of requested scopes and valid scopes
    return toolConfiguration.scopes
      .filter(scope => validScopeNames.includes(scope))
      .map(s => validScopes[s])
  }

  get canvasExtension() {
    const {toolConfiguration} = this.props

    if (!toolConfiguration.extensions) {
      return null
    }

    // Get Canvas specific extensions from the tool config
    return toolConfiguration.extensions.find(ext => ext.platform === 'canvas.instructure.com')
  }

  get placements() {
    const {validPlacements} = this.props
    const extension = this.canvasExtension

    if (!extension) {
      return []
    }

    if (!extension?.settings?.placements) {
      return []
    }

    // Intersection of requested placements and valid placements
    return extension.settings.placements.filter(placement => validPlacements.includes(placement.placement))
  }

  componentDidMount() {
    const {dispatch, setEnabledScopes} = this.props
    const initialScopes = this.scopes.map(s => this.invertedScopes[s])

    dispatch(setEnabledScopes(initialScopes))
  }

  handleScopeChange = e => {
    const {dispatch, setEnabledScopes} = this.props
    const value = this.invertedScopes[e.target.value]
    const newEnabledScopes = this.props.enabledScopes.slice()

    dispatch(setEnabledScopes(this.toggleArrayItem(newEnabledScopes, value)))
  }

  handlePlacementChange = e => {
    const {dispatch, setDisabledPlacements} = this.props
    const value = e.target.value
    const newDisabledPlacements = this.props.disabledPlacements.slice()

    dispatch(setDisabledPlacements(this.toggleArrayItem(newDisabledPlacements, value)))
  }

  setPrivacyLevel = e => {
    const {dispatch, setPrivacyLevel} = this.props
    dispatch(setPrivacyLevel(e.target.value))
  }

  messageTypeFor = placement => {
    const extension = this.canvasExtension
    const place = extension?.settings?.placements?.find(p => p.placement === placement)
    if (!place) {
      return null
    }

    return place.message_type
  }

  toggleArrayItem(array, value) {
    if (array.includes(value)) {
      const removeAtIndex = array.indexOf(value)
      array.splice(removeAtIndex, 1)
    } else {
      array.push(value)
    }
    return array
  }

  updateCustomFields = (e) => {
    const customFieldsObject = customFieldsStringToObject(e.target.value)
    const toUpdate = Object.keys(customFieldsObject).length > 0 ? customFieldsObject : null
    this.setState({custom_fields: e.target.value, valid: !!toUpdate})
    this.props.updateToolConfiguration(
      toUpdate,
      'custom_fields'
    )
  }

  scopeTable() {
    const scopes = this.scopes
    if (scopes.length === 0) {
      return null
    }

    return (
      <CustomizationTable
        name={I18n.t('Services')}
        options={scopes}
        onOptionToggle={this.handleScopeChange}
        selectedOptions={this.props.enabledScopes.map(s => this.props.validScopes[s])}
        type="scope"
      />
    )
  }

  placementTable() {
    const placements = this.placements
    if (placements.length === 0) {
      return null
    }
    return (
      <CustomizationTable
        name={I18n.t('Placements')}
        options={placements.map(p => p.placement)}
        onOptionToggle={this.handlePlacementChange}
        selectedOptions={this.props.disabledPlacements}
        type="placement"
        messageTypeFor={this.messageTypeFor}
      />
    )
  }

  customFields() {
    const messages = [{text: I18n.t('One per line. Format: name=value'), type: 'hint'}]
    if (this.props.showCustomizationMessages && !this.state.valid) {
      messages.push(validationMessage[0])
    }
    return (
      <TextArea
        label={I18n.t('Custom Fields')}
        maxHeight="20rem"
        name="custom_fields"
        onChange={this.updateCustomFields}
        value={this.state.custom_fields}
        messages={messages}
      />
    )
  }

  render() {
    return (
      <View>
        <Heading level="h2" as="h2" margin="0 0 x-small">
          {I18n.t('Customize Configuration')}
        </Heading>
        {this.scopeTable()}
        {this.placementTable()}
        <OtherOptions defaultValue={this.privacyLevel} onChange={this.setPrivacyLevel} />
        {this.customFields()}
      </View>
    )
  }
}
