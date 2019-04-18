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

import View from '@instructure/ui-layout/lib/components/View'
import FormFieldGroup from '@instructure/ui-form-field/lib/components/FormFieldGroup';
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent';

import RequiredValues from './RequiredValues'
import Services from './Services'
import AdditionalSettings from './AdditionalSettings';
import Placements from './Placements';

export default class ManualConfigurationForm extends React.Component {
  generateToolConfiguration = () => {
    const toolConfig = {
      ...this.requiredRef.generateToolConfigurationPart(),
      scopes: this.servicesRef.generateToolConfigurationPart(),
      ...this.additionalRef.generateToolConfigurationPart()
    }
    toolConfig.extensions[0].placements = this.placementsRef.generateToolConfigurationPart();
    return toolConfig
  }

  setRequiredRef = node => this.requiredRef = node;

  setServicesRef = node => this.servicesRef = node;

  setAdditionalRef = node => this.additionalRef = node;

  setPlacementsRef = node => this.placementsRef = node;

  render() {
    const { toolConfiguration, validScopes, validPlacements } = this.props;

    return (
      <View>
        <FormFieldGroup
          description={<ScreenReaderContent>{I18n.t('Manual Configuration')}</ScreenReaderContent>}
          layout="stacked"
        >
          <RequiredValues ref={this.setRequiredRef} toolConfiguration={toolConfiguration} />
          <Services ref={this.setServicesRef}  validScopes={validScopes} scopes={toolConfiguration.scopes} />
          <AdditionalSettings ref={this.setAdditionalRef}  additionalSettings={this.additionalSettings} custom_fields={this.custom_fields} />
          <Placements ref={this.setPlacementsRef}  validPlacements={validPlacements} placements={this.placements} />
        </FormFieldGroup>
      </View>
    )
  }
}

ManualConfigurationForm.propTypes = {
  toolConfiguration: PropTypes.object,
  validScopes: PropTypes.object.isRequired,
  validPlacements: PropTypes.arrayOf(PropTypes.string).isRequired
}

ManualConfigurationForm.defaultProps = {
  toolConfiguration: {}
}
