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

import {Alert} from '@instructure/ui-alerts'
import {View} from '@instructure/ui-view'
import {CheckboxGroup, Checkbox} from '@instructure/ui-checkbox'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {ToggleDetails} from '@instructure/ui-toggle-details'

const I18n = useI18nScope('react_developer_keys')

export default class Services extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      scopes: this.props.scopes,
    }
  }

  generateToolConfigurationPart = () => {
    return this.state.scopes
  }

  valid = () => true

  handleScopesSelectionChange = scopes => {
    this.setState({scopes})
  }

  render() {
    const {scopes} = this.state
    const {validScopes} = this.props

    return (
      <ToggleDetails summary={I18n.t('LTI Advantage Services')} fluidWidth={true}>
        <View as="div" margin="small">
          <Alert variant="warning" margin="small">
            {I18n.t(
              'Services must be supported by the tool in order to work. Check with your Tool Vendor to ensure service capabilities.'
            )}
          </Alert>
          <CheckboxGroup
            name="services"
            onChange={this.handleScopesSelectionChange}
            value={scopes}
            description={
              <ScreenReaderContent>{I18n.t('Check Services to enable')}</ScreenReaderContent>
            }
          >
            {Object.keys(validScopes).map(key => {
              return <Checkbox key={key} label={validScopes[key]} value={key} variant="toggle" />
            })}
          </CheckboxGroup>
        </View>
      </ToggleDetails>
    )
  }
}

Services.propTypes = {
  validScopes: PropTypes.object,
  scopes: PropTypes.arrayOf(PropTypes.string),
}

Services.defaultProps = {
  scopes: [],
  validScopes: {},
}
