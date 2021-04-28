/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {Alert} from '@instructure/ui-alerts'
import {View} from '@instructure/ui-view'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import {TextInput} from '@instructure/ui-text-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {ToggleDetails} from '@instructure/ui-toggle-details'

export default class Placement extends React.Component {
  constructor(props) {
    super(props)
    let placement
    if (this.alwaysDeeplinking.includes(props.placementName)) {
      placement = {...props.placement, message_type: 'LtiDeepLinkingRequest'}
    } else if (!props.placement.message_type) {
      placement = {...props.placement, message_type: 'LtiResourceLinkRequest'}
    } else {
      placement = props.placement
    }

    this.state = {placement}
  }

  alwaysDeeplinking = [
    'editor_button',
    'migration_selection',
    'homework_submission',
    'conference_selection'
  ]

  canBeEither = ['assignment_selection', 'link_selection']

  isAlwaysDeeplinking(placementName) {
    return this.alwaysDeeplinking.includes(placementName)
  }

  messageTypeSelectable(placementName) {
    return this.canBeEither.includes(placementName)
  }

  isSpecialType(placementName) {
    return (
      this.isAlwaysDeeplinking(placementName) ||
      (this.state.placement.message_type === 'LtiDeepLinkingRequest' &&
        this.messageTypeSelectable(placementName))
    )
  }

  generateToolConfigurationPart = () => {
    return this.state.placement
  }

  valid = () => {
    return true
  }

  handleTargetLinkUriChange = e => {
    const value = e.target.value
    this.setState(state => ({placement: {...state.placement, target_link_uri: value}}))
  }

  handleMessageTypeChange = (_, value) =>
    this.setState(state => ({placement: {...state.placement, message_type: value}}))

  handleIconUrlChange = e => {
    const value = e.target.value
    this.setState(state => ({placement: {...state.placement, icon_url: value}}))
  }

  handleTextChange = e => {
    const value = e.target.value
    this.setState(state => ({placement: {...state.placement, text: value}}))
  }

  handleSelectionHeightChange = e => {
    const value = e.target.value
    const numVal = parseInt(value, 10)
    this.setState(state => ({
      placement: {...state.placement, selection_height: !Number.isNaN(numVal) ? numVal : ''}
    }))
  }

  handleSelectionWidthChange = e => {
    const value = e.target.value
    const numVal = parseInt(value, 10)
    this.setState(state => ({
      placement: {...state.placement, selection_width: !Number.isNaN(numVal) ? numVal : ''}
    }))
  }

  render() {
    const {placement} = this.state
    const {placementName, displayName} = this.props

    return (
      <View as="div" margin="medium 0">
        <ToggleDetails summary={displayName} fluidWidth>
          <View as="div" margin="small">
            <FormFieldGroup
              description={<ScreenReaderContent>{I18n.t('Placement Values')}</ScreenReaderContent>}
            >
              {this.isSpecialType(placementName) ? (
                <Alert variant="warning" margin="small">
                  {I18n.t(
                    'This placement requires Deep Link support by the vendor. Check with your tool vendor to ensure they support this functionality'
                  )}
                </Alert>
              ) : null}
              <FormFieldGroup
                description={<ScreenReaderContent>{I18n.t('Request Values')}</ScreenReaderContent>}
                layout="columns"
              >
                <TextInput
                  name={`${placementName}_target_link_uri`}
                  value={placement.target_link_uri}
                  label={I18n.t('Target Link URI')}
                  onChange={this.handleTargetLinkUriChange}
                />
                <RadioInputGroup
                  name={`${placementName}_message_type`}
                  value={placement.message_type}
                  description={I18n.t('Select Message Type')}
                  required
                  onChange={this.handleMessageTypeChange}
                  disabled={!this.messageTypeSelectable(placementName)}
                >
                  <RadioInput value="LtiDeepLinkingRequest" label="LtiDeepLinkingRequest" />
                  <RadioInput value="LtiResourceLinkRequest" label="LtiResourceLinkRequest" />
                </RadioInputGroup>
              </FormFieldGroup>
              <FormFieldGroup
                description={<ScreenReaderContent>{I18n.t('Label Values')}</ScreenReaderContent>}
                layout="columns"
              >
                <TextInput
                  name={`${placementName}_icon_url`}
                  value={placement.icon_url}
                  label={I18n.t('Icon Url')}
                  onChange={this.handleIconUrlChange}
                />
                <TextInput
                  name={`${placementName}_text`}
                  value={placement.text}
                  label={I18n.t('Text')}
                  onChange={this.handleTextChange}
                />
              </FormFieldGroup>
              <FormFieldGroup
                description={<ScreenReaderContent>{I18n.t('Display Values')}</ScreenReaderContent>}
                layout="columns"
              >
                <TextInput
                  name={`${placementName}_selection_height`}
                  value={placement.selection_height && placement.selection_height.toString()}
                  label={I18n.t('Selection Height')}
                  onChange={this.handleSelectionHeightChange}
                />
                <TextInput
                  name={`${placementName}_selection_width`}
                  value={placement.selection_width && placement.selection_width.toString()}
                  label={I18n.t('Selection Width')}
                  onChange={this.handleSelectionWidthChange}
                />
              </FormFieldGroup>
            </FormFieldGroup>
          </View>
        </ToggleDetails>
      </View>
    )
  }
}

Placement.propTypes = {
  displayName: PropTypes.string.isRequired,
  placement: PropTypes.object,
  placementName: PropTypes.string.isRequired
}

Placement.defaultProps = {
  placement: {}
}
