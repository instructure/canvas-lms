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

import {Checkbox, TextArea, TextInput} from '@instructure/ui-forms'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {Grid} from '@instructure/ui-layout'
import I18n from 'i18n!react_developer_keys'
import {ScreenReaderContent} from '@instructure/ui-a11y'
import React from 'react'
import PropTypes from 'prop-types'

import Scopes from './Scopes'
import ToolConfiguration from './ToolConfiguration'

const validationMessage = [
  {text: I18n.t('Must have at least one redirect_uri defined.'), type: 'error'}
]

export default class NewKeyForm extends React.Component {
  generateToolConfiguration = () => {
    return this.toolConfigRef.generateToolConfiguration()
  }

  valid = () => {
    return this.toolConfigRef.valid()
  }

  get keyForm() {
    return this.keyFormRef
  }

  setKeyFormRef = node => {
    this.keyFormRef = node
  }

  setToolConfigRef = node => {
    this.toolConfigRef = node
  }

  handleRequireScopesChange = () => {
    this.props.updateDeveloperKey('require_scopes', !this.props.developerKey.require_scopes)
  }

  handleTestClusterOnlyChange = () => {
    this.props.updateDeveloperKey('test_cluster_only', !this.props.developerKey.test_cluster_only)
  }

  render() {
    const {
      createLtiKeyState,
      developerKey,
      editing,
      showRequiredMessages,
      updateToolConfiguration,
      updateToolConfigurationUrl,
      toolConfigurationUrl,
      updateDeveloperKey,
      showCustomizationMessages
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
                  label={I18n.t('Key Name:')}
                  name="developer_key[name]"
                  value={developerKey.name}
                  onChange={e => updateDeveloperKey('name', e.target.value)}
                  placeholder="Unnamed Tool"
                  disabled={this.props.createLtiKeyState.customizing}
                />
                <TextInput
                  label={I18n.t('Owner Email:')}
                  name="developer_key[email]"
                  value={developerKey.email}
                  onChange={e => updateDeveloperKey('email', e.target.value)}
                  disabled={this.props.createLtiKeyState.customizing}
                />
                <TextArea
                  label={
                    this.props.createLtiKeyState.isLtiKey
                      ? I18n.t('* Redirect URIs:')
                      : I18n.t('Redirect URIs:')
                  }
                  name="developer_key[redirect_uris]"
                  value={developerKey.redirect_uris}
                  onChange={e => updateDeveloperKey('redirect_uris', e.target.value)}
                  resize="both"
                  messages={showRequiredMessages ? validationMessage : []}
                  disabled={this.props.createLtiKeyState.customizing}
                />
                {!this.props.createLtiKeyState.isLtiKey && (
                  <div>
                    <TextInput
                      label={I18n.t('Redirect URI (Legacy):')}
                      name="developer_key[redirect_uri]"
                      value={developerKey.redirect_uri}
                      onChange={e => updateDeveloperKey('redirect_uri', e.target.value)}
                    />
                    <TextInput
                      label={I18n.t('Vendor Code (LTI 2):')}
                      name="developer_key[vendor_code]"
                      value={developerKey.vendor_code}
                      onChange={e => updateDeveloperKey('vendor_code', e.target.value)}
                    />
                    <TextInput
                      label={I18n.t('Icon URL:')}
                      name="developer_key[icon_url]"
                      value={developerKey.icon_url}
                      onChange={e => updateDeveloperKey('icon_url', e.target.value)}
                    />
                  </div>
                )}
                <TextArea
                  label={I18n.t('Notes:')}
                  name="developer_key[notes]"
                  value={developerKey.notes}
                  onChange={e => updateDeveloperKey('notes', e.target.value)}
                  resize="both"
                  disabled={this.props.createLtiKeyState.customizing}
                />
                {ENV.enableTestClusterChecks ? (
                  <Checkbox
                    label={I18n.t('Test Cluster Only')}
                    name="developer_key[test_cluster_only]"
                    checked={developerKey.test_cluster_only}
                    onChange={this.handleTestClusterOnlyChange}
                    disabled={this.props.createLtiKeyState.customizing}
                  />
                ) : null}
              </FormFieldGroup>
            </Grid.Col>
            <Grid.Col width={8}>
              {createLtiKeyState.isLtiKey ? (
                <ToolConfiguration
                  ref={this.setToolConfigRef}
                  createLtiKeyState={createLtiKeyState}
                  setEnabledScopes={this.props.setEnabledScopes}
                  setDisabledPlacements={this.props.setDisabledPlacements}
                  setLtiConfigurationMethod={this.props.setLtiConfigurationMethod}
                  setPrivacyLevel={this.props.setPrivacyLevel}
                  dispatch={this.props.dispatch}
                  toolConfiguration={this.props.tool_configuration}
                  editing={editing}
                  showRequiredMessages={showRequiredMessages}
                  updateToolConfiguration={updateToolConfiguration}
                  updateToolConfigurationUrl={updateToolConfigurationUrl}
                  toolConfigurationUrl={toolConfigurationUrl}
                  showCustomizationMessages={showCustomizationMessages}
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
                />
              )}
            </Grid.Col>
          </Grid.Row>
        </Grid>
      </form>
    )
  }
}

NewKeyForm.defaultProps = {
  developerKey: {}
}

NewKeyForm.propTypes = {
  dispatch: PropTypes.func.isRequired,
  listDeveloperKeyScopesSet: PropTypes.func.isRequired,
  setDisabledPlacements: PropTypes.func.isRequired,
  setLtiConfigurationMethod: PropTypes.func.isRequired,
  setPrivacyLevel: PropTypes.func.isRequired,
  setEnabledScopes: PropTypes.func.isRequired,
  createLtiKeyState: PropTypes.shape({
    isLtiKey: PropTypes.bool.isRequired,
    customizing: PropTypes.bool.isRequired
  }).isRequired,
  developerKey: PropTypes.shape({
    notes: PropTypes.string,
    icon_url: PropTypes.string,
    vendor_code: PropTypes.string,
    redirect_uris: PropTypes.string,
    email: PropTypes.string,
    name: PropTypes.string,
    require_scopes: PropTypes.bool,
    tool_configuration: PropTypes.shape({
      oidc_initiation_url: PropTypes.string
    }),
    test_cluster_only: PropTypes.bool
  }),
  availableScopes: PropTypes.objectOf(
    PropTypes.arrayOf(
      PropTypes.shape({
        resource: PropTypes.string,
        scope: PropTypes.string
      })
    )
  ).isRequired,
  availableScopesPending: PropTypes.bool.isRequired,
  editing: PropTypes.bool.isRequired,
  tool_configuration: PropTypes.shape({
    oidc_initiation_url: PropTypes.string
  }),
  showRequiredMessages: PropTypes.bool,
  updateToolConfiguration: PropTypes.func,
  updateToolConfigurationUrl: PropTypes.func,
  updateDeveloperKey: PropTypes.func.isRequired,
  toolConfigurationUrl: PropTypes.string.isRequired,
  showCustomizationMessages: PropTypes.bool.isRequired
}
