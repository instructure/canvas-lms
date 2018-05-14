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
import Grid, {GridCol, GridRow} from '@instructure/ui-core/lib/components/Grid'
import IconSearchLine from 'instructure-icons/lib/Line/IconSearchLine'
import ScreenReaderContent from '@instructure/ui-core/lib/components/ScreenReaderContent'
import Spinner from '@instructure/ui-core/lib/components/Spinner'
import Text from '@instructure/ui-core/lib/components/Text'
import TextInput from '@instructure/ui-core/lib/components/TextInput'
import DeveloperKeyScopesList from './ScopesList'

export default class DeveloperKeyScopes extends React.Component {
  state = { filter: '' }

  handleFilterChange = e => {
    this.setState({
      filter: e.currentTarget.value
    })
  }

  body() {
    if (this.props.availableScopesPending) {
      return (
        <GridRow hAlign="space-around">
          <GridCol width={2}>
            <span id="scopes-loading-spinner">
              <Spinner title={I18n.t('Loading Available Scopes')} />
            </span>
          </GridCol>
        </GridRow>
      )
    }
    return (
      <GridRow>
        <GridCol>
          <DeveloperKeyScopesList
            availableScopes={this.props.availableScopes}
            filter={this.state.filter}
          />
        </GridCol>
      </GridRow>
    )
  }

  render() {
    return (
      <Grid>
        <GridRow rowSpacing="small">
          <GridCol>
            <Text size="medium" weight="bold">
              {I18n.t('Add Scope')}
            </Text>
          </GridCol>
          <GridCol width="auto">
            <TextInput
              label={<ScreenReaderContent />}
              placeholder={I18n.t('Search endpoints')}
              type="search"
              icon={() => <IconSearchLine />}
              onChange={this.handleFilterChange}
            />
          </GridCol>
        </GridRow>
        {this.body()}
      </Grid>
    )
  }
}

DeveloperKeyScopes.propTypes = {
  availableScopes: PropTypes.objectOf(PropTypes.arrayOf(
    PropTypes.shape({
      resource: PropTypes.string,
      scope: PropTypes.string
    })
  )).isRequired,
  availableScopesPending: PropTypes.bool.isRequired
}
