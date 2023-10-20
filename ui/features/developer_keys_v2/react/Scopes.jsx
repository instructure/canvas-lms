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

import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React from 'react'

import {Billboard} from '@instructure/ui-billboard'
import {Checkbox} from '@instructure/ui-checkbox'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import {Grid} from '@instructure/ui-grid'
import {IconWarningLine, IconSearchLine, IconInfoLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'
import {Tooltip} from '@instructure/ui-tooltip'

import ScopesList from './ScopesList'

const I18n = useI18nScope('react_developer_keys')

export default class Scopes extends React.Component {
  state = {filter: ''}

  handleFilterChange = e => {
    this.setState({
      filter: e.currentTarget.value,
    })
  }

  enforceScopesSrText() {
    return this.props.requireScopes
      ? I18n.t('Clicking the checkbox will cause scopes table to disappear below')
      : I18n.t('Clicking the checkbox will cause scopes table to appear below')
  }

  body() {
    const {developerKey} = this.props
    if (this.props.availableScopesPending) {
      return (
        <Grid.Row hAlign="space-around">
          <Grid.Col width={2}>
            <span id="scopes-loading-spinner">
              <Spinner renderTitle={I18n.t('Loading Available Scopes')} />
            </span>
          </Grid.Col>
        </Grid.Row>
      )
    }

    return (
      <Grid.Row>
        <Grid.Col>
          <View>
            {this.props.requireScopes ? (
              <ScopesList
                availableScopes={this.props.availableScopes}
                selectedScopes={developerKey ? developerKey.scopes : []}
                filter={this.state.filter}
                listDeveloperKeyScopesSet={this.props.listDeveloperKeyScopesSet}
                dispatch={this.props.dispatch}
              />
            ) : (
              <Billboard
                hero={<IconWarningLine />}
                size="large"
                headingAs="h2"
                headingLevel="h2"
                margin="xx-large"
                readOnly={true}
                heading={I18n.t(
                  'When scope enforcement is disabled, tokens have access to all endpoints available to the authorizing user.'
                )}
              />
            )}
          </View>
        </Grid.Col>
      </Grid.Row>
    )
  }

  render() {
    const searchEndpoints = I18n.t('Search endpoints')
    const {developerKey, updateDeveloperKey} = this.props
    const includeTooltip = I18n.t(
      'Permit usage of all “includes” parameters for this developer key. "Includes"' +
        ' parameters may grant access to additional data not included in the scopes selected below.'
    )

    return (
      <Grid>
        <Grid.Row rowSpacing="small">
          <Grid.Col data-automation="enforce_scopes">
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
          </Grid.Col>
          {this.props.requireScopes ? (
            <Grid.Col width="auto">
              <TextInput
                renderLabel={<ScreenReaderContent>{searchEndpoints}</ScreenReaderContent>}
                placeholder={searchEndpoints}
                type="search"
                renderAfterInput={() => <IconSearchLine />}
                onChange={this.handleFilterChange}
              />
            </Grid.Col>
          ) : null}
        </Grid.Row>
        {this.props.requireScopes && ENV.includesFeatureFlagEnabled && (
          <Grid.Row>
            <Grid.Col>
              <Checkbox
                inline={true}
                label={<Text>{I18n.t('Allow Include Parameters ')}</Text>}
                checked={developerKey.allow_includes}
                onChange={e => {
                  updateDeveloperKey('allow_includes', e.currentTarget.checked)
                }}
                data-automation="includes-checkbox"
              />
              &nbsp;
              <Tooltip renderTip={includeTooltip} on={['hover', 'focus']} color="primary">
                {/* eslint-disable-next-line jsx-a11y/no-noninteractive-tabindex */}
                <span tabIndex="0">
                  <IconInfoLine />
                  <ScreenReaderContent>{includeTooltip}</ScreenReaderContent>
                </span>
              </Tooltip>
            </Grid.Col>
          </Grid.Row>
        )}
        {this.body()}
      </Grid>
    )
  }
}

Scopes.propTypes = {
  availableScopes: PropTypes.objectOf(
    PropTypes.arrayOf(
      PropTypes.shape({
        resource: PropTypes.string,
        scope: PropTypes.string,
      })
    )
  ).isRequired,
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
    scopes: PropTypes.arrayOf(PropTypes.string),
    allow_includes: PropTypes.bool,
  }),
  requireScopes: PropTypes.bool,
  onRequireScopesChange: PropTypes.func.isRequired,
  updateDeveloperKey: PropTypes.func.isRequired,
}

Scopes.defaultProps = {
  developerKey: undefined,
  requireScopes: false,
}
