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

import Billboard from '@instructure/ui-billboard/lib/components/Billboard'
import Checkbox from '@instructure/ui-forms/lib/components/Checkbox'
import Grid, {GridCol, GridRow} from '@instructure/ui-layout/lib/components/Grid'
import IconWarning from '@instructure/ui-icons/lib/Line/IconWarning'
import IconSearchLine from '@instructure/ui-icons/lib/Line/IconSearch'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import Spinner from '@instructure/ui-elements/lib/components/Spinner'
import Text from '@instructure/ui-elements/lib/components/Text'
import TextInput from '@instructure/ui-forms/lib/components/TextInput'
import View from '@instructure/ui-layout/lib/components/View'

import DeveloperKeyScopesList from './ScopesList'

export default class DeveloperKeyScopes extends React.Component {
  state = { filter: '' }

  handleFilterChange = e => {
    this.setState({
      filter: e.currentTarget.value
    })
  }

  enforceScopesSrText () {
    return this.props.requireScopes
      ? I18n.t('Clicking the checkbox will cause scopes table to disappear below')
      : I18n.t('Clicking the checkbox will cause scopes table to appear below')
  }

  body() {
    const { developerKey } = this.props
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
          <View>
              {this.props.requireScopes
                ? <DeveloperKeyScopesList
                    availableScopes={this.props.availableScopes}
                    selectedScopes={developerKey ? developerKey.scopes : []}
                    filter={this.state.filter}
                    listDeveloperKeyScopesSet={this.props.listDeveloperKeyScopesSet}
                    dispatch={this.props.dispatch}
                  />
                : <Billboard
                    hero={<IconWarning />}
                    size="large"
                    headingAs="h2"
                    headingLevel="h2"
                    margin="xx-large"
                    readOnly
                    heading={I18n.t('When scope enforcement is disabled, tokens have access to all endpoints available to the authorizing user.')}
                  />

              }
          </View>
        </GridCol>
      </GridRow>
    )
  }

  render() {
    const searchEndpoints = I18n.t('Search endpoints')
    return (
      <Grid>
        <GridRow rowSpacing="small">
          <GridCol
            data-automation="enforce_scopes"
          >
            <Checkbox
              variant="toggle"
              label={
                <span>
                  <Text>{I18n.t('Enforce Scopes')}</Text>
                  <ScreenReaderContent>{this.enforceScopesSrText()}</ScreenReaderContent>
                </span>
              }
              checked={this.props.requireScopes}
              onChange={this.props.onRequireScopesChange}
            />
          </GridCol>
          {
            this.props.requireScopes
            ? (
              <GridCol width="auto">
                <ScreenReaderContent>{I18n.t('Add Scope')}</ScreenReaderContent>
                <TextInput
                  label={<ScreenReaderContent>{searchEndpoints}</ScreenReaderContent>}
                  placeholder={searchEndpoints}
                  type="search"
                  icon={() => <IconSearchLine />}
                  onChange={this.handleFilterChange}
                />
              </GridCol>
            )
            : null
          }
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
  availableScopesPending: PropTypes.bool.isRequired,
  dispatch: PropTypes.func.isRequired,
  listDeveloperKeyScopesSet: PropTypes.func.isRequired,
  developerKey: PropTypes.shape({
    notes: PropTypes.string,
    icon_url: PropTypes.string,
    vendor_code: PropTypes.string,
    redirect_uris: PropTypes.string,
    email: PropTypes.string,
    name: PropTypes.string,
    scopes: PropTypes.arrayOf(PropTypes.string)
  }),
  requireScopes: PropTypes.bool,
  onRequireScopesChange: PropTypes.func.isRequired
}

DeveloperKeyScopes.defaultProps = {
  developerKey: undefined,
  requireScopes: false
}
