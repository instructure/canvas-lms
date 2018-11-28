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
import Heading from '@instructure/ui-elements/lib/components/Heading'
import TextArea from '@instructure/ui-forms/lib/components/TextArea'
import View from '@instructure/ui-layout/lib/components/View'

import CustomizationTable from './CustomizationTable'

export default class CustomizationForm extends React.Component {
  static propTypes = {
    toolConfiguration: PropTypes.object.isRequired,
    validScopes: PropTypes.object.isRequired,
    validPlacements: PropTypes.arrayOf(PropTypes.string).isRequired,
    enabledScopes: PropTypes.arrayOf(PropTypes.string).isRequired,
    disabledPlacements: PropTypes.arrayOf(PropTypes.string).isRequired,
    dispatch: PropTypes.func.isRequired,
    setEnabledScopes: PropTypes.func.isRequired,
    setDisabledPlacements: PropTypes.func.isRequired
  }

  constructor(props) {
    super(props)
    this.invertedScopes = invert(this.props.validScopes)
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
    return toolConfiguration.extensions.find(
      ext => ext.platform === 'canvas.instructure.com'
    )
  }

  get placements() {
    const {validPlacements} = this.props
    const extension = this.canvasExtension

    if (!extension) {
      return []
    }

    if (!(extension && extension.settings)) {
      return []
    }

    // Intersection of requested placements and valid placements
    return Object.keys(extension.settings).filter(placement => validPlacements.includes(placement))
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
    const {dispatch, setDisabledPlacements, validPlacements} = this.props
    const value = e.target.value
    const newDisabledPlacements = this.props.disabledPlacements.slice()

    dispatch(setDisabledPlacements(this.toggleArrayItem(newDisabledPlacements, value)))
  }

  messageTypeFor = (placement) => {
    const extension = this.canvasExtension

    if (!(extension && extension.settings[placement])) {
      return null
    }

    return extension.settings[placement].message_type
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
        options={placements}
        onOptionToggle={this.handlePlacementChange}
        selectedOptions={this.props.disabledPlacements}
        type="placement"
        messageTypeFor={this.messageTypeFor}
      />
    )
  }

  customFields() {
    return (
      <TextArea
        label={I18n.t('Custom Fields')}
        maxHeight="20rem"
        width="50%"
        messages={[{text: I18n.t('One per line. Format: name=value'), type: 'hint'}]}
        name="custom_fields"
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
        {this.customFields()}
      </View>
    )
  }
}
