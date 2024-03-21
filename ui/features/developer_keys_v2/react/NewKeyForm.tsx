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

import {Button, IconButton} from '@instructure/ui-buttons'
import {TextInput} from '@instructure/ui-text-input'
import {TextArea} from '@instructure/ui-text-area'
import {Checkbox} from '@instructure/ui-checkbox'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {IconInfoLine} from '@instructure/ui-icons'
import {Tooltip} from '@instructure/ui-tooltip'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Grid} from '@instructure/ui-grid'
import {useScope as useI18nScope} from '@canvas/i18n'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import type {FormMessageChild, FormMessageType} from '@instructure/ui-form-field/src/FormPropTypes'

import React from 'react'

import Scopes from './Scopes'
import ToolConfigurationForm from './ToolConfigurationForm'
import type {AvailableScope} from './reducers/listScopesReducer'
import type {DeveloperKey} from '../model/api/DeveloperKey'

export type NewKeyFormProps = {
  dispatch: Function
  listDeveloperKeyScopesSet: Function
  isLtiKey: boolean | undefined
  isRedirectUriRequired: boolean | undefined
  developerKey: DeveloperKey
  availableScopes: Record<string, AvailableScope>
  availableScopesPending: boolean
  editing: boolean
  tool_configuration: {
    oidc_initiation_url?: string
  }
  showRequiredMessages: boolean
  showMissingRedirectUrisMessage: boolean | undefined
  updateToolConfiguration: (update: any, field?: string | null, sync?: boolean) => void
  updateToolConfigurationUrl: Function
  updateDeveloperKey: Function
  toolConfigurationUrl: string | null
  configurationMethod: string
  updateConfigurationMethod: Function
  hasRedirectUris: boolean
  syncRedirectUris: Function
}

const I18n = useI18nScope('react_developer_keys')

const validationMessage: {
  text: FormMessageChild
  type: FormMessageType
}[] = [{text: I18n.t('Must have at least one redirect_uri defined.'), type: 'error'}]

const clientCredentialsAudienceTooltip = I18n.t(
  'Will credentials issued by this key be presented to Canvas or to a peer service (e.g. Canvas Data)?'
)

export default class NewKeyForm extends React.Component<NewKeyFormProps> {
  keyFormRef: HTMLFormElement | null = null

  toolConfigRef: ToolConfigurationForm | null = null

  state = {
    invalidJson: null,
    jsonString: null,
    canPrettify: false,
  }

  static defaultProps = {
    developerKey: {},
  }

  generateToolConfiguration = () => {
    return this.toolConfigRef?.generateToolConfiguration()
  }

  valid = () => {
    return this.toolConfigRef?.valid()
  }

  get keyForm() {
    return this.keyFormRef
  }

  setKeyFormRef = (node: HTMLFormElement | null) => {
    this.keyFormRef = node
  }

  setToolConfigRef = (node: ToolConfigurationForm) => {
    this.toolConfigRef = node
  }

  handleRequireScopesChange = () => {
    this.props.updateDeveloperKey('require_scopes', !this.props.developerKey.require_scopes)
  }

  handleTestClusterOnlyChange = () => {
    this.props.updateDeveloperKey('test_cluster_only', !this.props.developerKey.test_cluster_only)
  }

  updatePastedJson = (value: string, prettify: boolean = false) => {
    try {
      const settings = JSON.parse(value)
      const jsonString = prettify ? JSON.stringify(settings, null, 2) : value
      this.setState({invalidJson: null, jsonString, canPrettify: !prettify})

      if (!this.props.hasRedirectUris) {
        this.props.updateDeveloperKey('redirect_uris', settings.target_link_uri || '')
      }

      this.updateToolConfiguration(settings)
    } catch (e) {
      if (e instanceof SyntaxError) {
        this.setState({invalidJson: value, canPrettify: false})
      }
    }
  }

  prettifyPastedJson = () => {
    if (this.state.jsonString) {
      this.updatePastedJson(this.state.jsonString, true)
    }
  }

  updateToolConfiguration = (update: any) => {
    this.props.updateToolConfiguration(update)
  }

  syncRedirectUris = () => {
    this.props.syncRedirectUris()
  }

  render() {
    const {
      isLtiKey,
      isRedirectUriRequired,
      developerKey,
      editing,
      showRequiredMessages,
      showMissingRedirectUrisMessage,
      updateToolConfigurationUrl,
      toolConfigurationUrl,
      updateDeveloperKey,
    } = this.props

    return (
      <form ref={this.setKeyFormRef}>
        <Grid hAlign="center">
          <Grid.Row>
            <Grid.Col width={3}>
              <FormFieldGroup
                rowSpacing="small"
                vAlign="middle"
                description={
                  <ScreenReaderContent>{I18n.t('Developer Key Settings')}</ScreenReaderContent>
                }
              >
                <TextInput
                  renderLabel={I18n.t('Key Name:')}
                  name="developer_key[name]"
                  value={developerKey.name || ''}
                  onChange={e => updateDeveloperKey('name', e.target.value)}
                  placeholder="Unnamed Tool"
                />
                <TextInput
                  renderLabel={I18n.t('Owner Email:')}
                  name="developer_key[email]"
                  value={developerKey.email || ''}
                  onChange={e => updateDeveloperKey('email', e.target.value)}
                />
                <TextArea
                  label={
                    isRedirectUriRequired ? I18n.t('* Redirect URIs:') : I18n.t('Redirect URIs:')
                  }
                  name="developer_key[redirect_uris]"
                  value={developerKey.redirect_uris}
                  onChange={e => updateDeveloperKey('redirect_uris', e.target.value)}
                  resize="both"
                  messages={showMissingRedirectUrisMessage ? validationMessage : []}
                />
                {this.props.configurationMethod === 'json' && (
                  <div>
                    <Button onClick={this.syncRedirectUris} color="primary">
                      {I18n.t('Sync URIs')}
                    </Button>
                  </div>
                )}
                {!isLtiKey && (
                  <div>
                    <TextInput
                      renderLabel={I18n.t('Redirect URI (Legacy):')}
                      name="developer_key[redirect_uri]"
                      value={developerKey.redirect_uri || ''}
                      onChange={e => updateDeveloperKey('redirect_uri', e.target.value)}
                    />
                    <TextInput
                      renderLabel={I18n.t('Vendor Code (LTI 2):')}
                      name="developer_key[vendor_code]"
                      value={developerKey.vendor_code || ''}
                      onChange={e => updateDeveloperKey('vendor_code', e.target.value)}
                    />
                    <TextInput
                      renderLabel={I18n.t('Icon URL:')}
                      name="developer_key[icon_url]"
                      value={developerKey.icon_url || ''}
                      onChange={e => updateDeveloperKey('icon_url', e.target.value)}
                    />
                  </div>
                )}
                <TextArea
                  label={I18n.t('Notes:')}
                  name="developer_key[notes]"
                  value={developerKey.notes || ''}
                  onChange={e => updateDeveloperKey('notes', e.target.value)}
                  resize="both"
                />
                {/* @ts-expect-error */}
                {ENV.enableTestClusterChecks && !isLtiKey ? (
                  <Checkbox
                    label={I18n.t('Test Cluster Only')}
                    name="developer_key[test_cluster_only]"
                    checked={Boolean(developerKey.test_cluster_only)}
                    onChange={this.handleTestClusterOnlyChange}
                  />
                ) : null}
                {!isLtiKey ? (
                  <SimpleSelect
                    renderLabel={
                      <div>
                        <span>{I18n.t('Client Credentials Audience')}</span>
                        <Tooltip
                          renderTip={clientCredentialsAudienceTooltip}
                          on={['click', 'focus']}
                          color="primary"
                        >
                          <IconButton
                            renderIcon={IconInfoLine}
                            withBackground={false}
                            withBorder={false}
                            screenReaderLabel={I18n.t('toggle tooltip')}
                          />
                        </Tooltip>
                      </div>
                    }
                    name="developer_key[client_credentials_audience]"
                    value={developerKey.client_credentials_audience || undefined}
                    onChange={(_, {value}) =>
                      updateDeveloperKey('client_credentials_audience', value)
                    }
                  >
                    <SimpleSelect.Option id="audience-internal" value="internal">
                      {I18n.t('Canvas')}
                    </SimpleSelect.Option>
                    <SimpleSelect.Option id="audience-external" value="external">
                      {I18n.t('Peer Service')}
                    </SimpleSelect.Option>
                  </SimpleSelect>
                ) : null}
              </FormFieldGroup>
            </Grid.Col>
            <Grid.Col width={8}>
              {isLtiKey ? (
                <ToolConfigurationForm
                  ref={this.setToolConfigRef}
                  toolConfiguration={this.props.tool_configuration}
                  editing={editing}
                  showRequiredMessages={showRequiredMessages}
                  updateToolConfigurationUrl={updateToolConfigurationUrl}
                  toolConfigurationUrl={toolConfigurationUrl}
                  configurationMethod={this.props.configurationMethod}
                  updateConfigurationMethod={this.props.updateConfigurationMethod}
                  // @ts-expect-error
                  validScopes={ENV.validLtiScopes}
                  // @ts-expect-error
                  validPlacements={ENV.validLtiPlacements}
                  invalidJson={this.state.invalidJson}
                  jsonString={this.state.jsonString}
                  updatePastedJson={this.updatePastedJson}
                  canPrettify={this.state.canPrettify}
                  prettifyPastedJson={this.prettifyPastedJson}
                />
              ) : (
                <Scopes
                  availableScopes={this.props.availableScopes}
                  availableScopesPending={this.props.availableScopesPending}
                  developerKey={this.props.developerKey}
                  requireScopes={developerKey.require_scopes}
                  onRequireScopesChange={this.handleRequireScopesChange}
                  dispatch={this.props.dispatch}
                  listDeveloperKeyScopesSet={this.props.listDeveloperKeyScopesSet}
                  updateDeveloperKey={updateDeveloperKey}
                />
              )}
            </Grid.Col>
          </Grid.Row>
        </Grid>
      </form>
    )
  }
}
