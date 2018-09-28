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
import TextArea from '@instructure/ui-forms/lib/components/TextArea'
import View from '@instructure/ui-layout/lib/components/View'

import CustomizationTable from './CustomizationTable'

export default class CustomizationForm extends React.Component {
  propTypes = {
    toolConfiguration: PropTypes.object.isRequired,
    validScopes: PropTypes.object.isRequired,
    validPlacements: PropTypes.arrayOf(PropTypes.string).isRequired
  }

  get scopes() {
    const {toolConfiguration, validScopes} = this.props
    const validScopeNames = Object.keys(validScopes)

    if (!toolConfiguration.scopes) {
      return []
    }

    // Intersection of requested scopes and valid scopes
    return toolConfiguration.scopes.filter(scope => validScopeNames.includes(scope)).map(s => validScopes[s])
  }

  get placements() {
    const {toolConfiguration, validPlacements} = this.props

    if (!toolConfiguration.extensions) {
      return []
    }

    // Get Canvas specific extensions from the tool config
    const extension = toolConfiguration.extensions.find(ext => (
      ext.platform === 'canvas.instructure.com'
    ))

    if (!(extension && extension.settings)) {
      return []
    }

    // Intersection of requested placements and valid placements
    return Object.keys(extension.settings).filter(placement => validPlacements.includes(placement))
  }

  scopeTable() {
    const scopes = this.scopes
    if (scopes.length === 0) {
      return null
    }
    return (
      <CustomizationTable
        name={I18n.t('Services')}
        type="service"
        options={scopes}
        onOptionToggle={() => {}}
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
        type="placement"
        options={placements}
        onOptionToggle={() => {}}
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
