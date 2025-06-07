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

import {useScope as createI18nScope} from '@canvas/i18n'
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

const I18n = createI18nScope('react_developer_keys')

interface Scope {
  controller?: string
  action?: string
  verb?: string
  path?: string
  scope: string
  resource: string
  resource_name?: string
}

interface DeveloperKey {
  notes?: string | null
  icon_url?: string | null
  vendor_code?: string | null
  redirect_uris?: string | null
  email?: string | null
  name?: string | null
  scopes?: string[]
  allow_includes?: boolean
  require_scopes?: boolean | null
}

interface ScopesProps {
  availableScopes: Record<string, Scope | Scope[]>
  availableScopesPending: boolean
  dispatch: Function
  listDeveloperKeyScopesSet: Function
  developerKey?: DeveloperKey
  requireScopes?: boolean | null
  onRequireScopesChange: (event: React.ChangeEvent<HTMLInputElement>) => void
  updateDeveloperKey: Function
}

interface ScopesState {
  filter: string
}

export default class Scopes extends React.Component<ScopesProps, ScopesState> {
  state = {filter: ''}

  handleFilterChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    this.setState({
      filter: e.currentTarget.value,
    })
  }

  enforceScopesSrText() {
    const requireScopes = this.props.requireScopes ?? false
    return requireScopes
      ? I18n.t('Clicking the checkbox will cause scopes table to disappear below')
      : I18n.t('Clicking the checkbox will cause scopes table to appear below')
  }

  body() {
    const {developerKey} = this.props
    const requireScopes = this.props.requireScopes ?? false
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
            {requireScopes ? (
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
                  'When scope enforcement is disabled, tokens have access to all endpoints available to the authorizing user.',
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
    const requireScopes = this.props.requireScopes ?? false
    const includeTooltip = I18n.t(
      'Permit usage of all "includes" parameters for this developer key. "Includes"' +
        ' parameters may grant access to additional data not included in the scopes selected below.',
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
              checked={requireScopes}
              onChange={this.props.onRequireScopesChange}
            />
          </Grid.Col>
          {requireScopes ? (
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
        {requireScopes && (
          <Grid.Row>
            <Grid.Col>
              <Checkbox
                inline={true}
                label={<Text>{I18n.t('Allow Include Parameters ')}</Text>}
                checked={developerKey?.allow_includes}
                onChange={e => {
                  updateDeveloperKey('allow_includes', e.currentTarget.checked)
                }}
                data-automation="includes-checkbox"
              />
              &nbsp;
              <Tooltip renderTip={includeTooltip} on={['hover', 'focus']} color="primary">
                {/* eslint-disable-next-line jsx-a11y/no-noninteractive-tabindex */}
                <span tabIndex={0}>
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
