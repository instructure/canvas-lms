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
import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React from 'react'
import get from 'lodash/get'

import {View} from '@instructure/ui-view'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

import RequiredValues from './RequiredValues'
import Services from './Services'
import AdditionalSettings from './AdditionalSettings'
import Placements from './Placements'

const I18n = useI18nScope('react_developer_keys')

export default class ManualConfigurationForm extends React.Component {
  state = {
    showMessages: false,
  }

  generateToolConfiguration = () => {
    const toolConfig = {
      ...this.requiredRef.generateToolConfigurationPart(),
      scopes: this.servicesRef.generateToolConfigurationPart(),
      ...this.additionalRef.generateToolConfigurationPart(),
    }
    toolConfig.extensions[0].settings.placements =
      this.placementsRef.generateToolConfigurationPart()
    return toolConfig
  }

  valid = () => {
    this.setState({showMessages: true})
    return (
      this.requiredRef.valid() &&
      this.servicesRef.valid() &&
      this.additionalRef.valid() &&
      this.placementsRef.valid()
    )
  }

  setRequiredRef = node => (this.requiredRef = node)

  setServicesRef = node => (this.servicesRef = node)

  setAdditionalRef = node => (this.additionalRef = node)

  setPlacementsRef = node => (this.placementsRef = node)

  additionalSettings = () => {
    const {toolConfiguration} = this.props
    return get(toolConfiguration, ['extensions', '0'])
  }

  customFields = () => {
    const {toolConfiguration} = this.props
    return get(toolConfiguration, ['custom_fields'])
  }

  placements = () => {
    const {toolConfiguration} = this.props
    return get(toolConfiguration, ['extensions', '0', 'settings', 'placements'])
  }

  render() {
    const {toolConfiguration, validScopes, validPlacements} = this.props

    return (
      <View>
        <FormFieldGroup
          description={<ScreenReaderContent>{I18n.t('Manual Configuration')}</ScreenReaderContent>}
          layout="stacked"
        >
          <RequiredValues
            ref={this.setRequiredRef}
            toolConfiguration={toolConfiguration}
            showMessages={this.state.showMessages}
          />
          <Services
            ref={this.setServicesRef}
            validScopes={validScopes}
            scopes={toolConfiguration.scopes}
          />
          <AdditionalSettings
            ref={this.setAdditionalRef}
            additionalSettings={this.additionalSettings()}
            custom_fields={this.customFields()}
          />
          <Placements
            ref={this.setPlacementsRef}
            validPlacements={validPlacements}
            placements={this.placements()}
          />
        </FormFieldGroup>
      </View>
    )
  }
}

ManualConfigurationForm.propTypes = {
  toolConfiguration: PropTypes.object,
  validScopes: PropTypes.object.isRequired,
  validPlacements: PropTypes.arrayOf(PropTypes.string).isRequired,
}

ManualConfigurationForm.defaultProps = {
  toolConfiguration: {},
}
