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

import Checkbox from '@instructure/ui-forms/lib/components/Checkbox'
import FormFieldGroup from '@instructure/ui-forms/lib/components/FormFieldGroup'
import Grid, {GridCol, GridRow} from '@instructure/ui-layout/lib/components/Grid'
import I18n from 'i18n!react_developer_keys'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import TextArea from '@instructure/ui-forms/lib/components/TextArea'
import TextInput from '@instructure/ui-forms/lib/components/TextInput'
import React from 'react'
import PropTypes from 'prop-types'

import DeveloperKeyScopes from './Scopes'

export default class DeveloperKeyFormFields extends React.Component {
  constructor (props) {
    super(props)

    const { developerKey } = props
    this.state = {
      requireScopes: developerKey && developerKey.require_scopes,
      testClusterOnly: developerKey && developerKey.test_cluster_only
    }
  }

  get keyForm () {
    return this.keyFormRef
  }

  get requireScopes () {
    return this.state.requireScopes
  }

  get testClusterOnly () {
    return this.state.testClusterOnly
  }

  setKeyFormRef = node => { this.keyFormRef = node }

  fieldValue(field, defaultValue) {
    const {developerKey} = this.props
    if (Object.keys(developerKey).length > 0) {
      return developerKey[field] || defaultValue
    }
    return developerKey[field]
  }

  handleRequireScopesChange = () => {
    this.setState({ requireScopes: !this.state.requireScopes })
  }

  handleTestClusterOnlyChange = () => {
    this.setState({ testClusterOnly: !this.state.testClusterOnly })
  }

  renderTestClusterOnlyCheckbox() {
    if (ENV.enableTestClusterChecks) {
      return (
        <Checkbox
          label={I18n.t('Test Cluster Only')}
          name="developer_key[test_cluster_only]"
          checked={this.state.testClusterOnly}
          onChange={this.handleTestClusterOnlyChange}
        />
      )
    }
  }

  render() {
    return (
      <form ref={this.setKeyFormRef}>
        <Grid hAlign="center">
          <GridRow>
            <GridCol width={3}>
              <FormFieldGroup
                rowSpacing="small"
                vAlign="middle"
                description={<ScreenReaderContent>{I18n.t('Developer Key Settings')}</ScreenReaderContent>}
              >
                <TextInput
                  label={I18n.t('Key Name:')}
                  name="developer_key[name]"
                  defaultValue={this.fieldValue('name', 'Unnamed Tool')}
                />
                <TextInput
                  label={I18n.t('Owner Email:')}
                  name="developer_key[email]"
                  defaultValue={this.fieldValue('email')}
                />
                <TextInput
                  label={I18n.t('Redirect URI (Legacy):')}
                  name="developer_key[redirect_uri]"
                  defaultValue={this.fieldValue('redirect_uri')}
                />
                <TextArea
                  label={I18n.t('Redirect URIs:')}
                  name="developer_key[redirect_uris]"
                  defaultValue={this.fieldValue('redirect_uris')}
                  resize="both"
                />
                <TextInput
                  label={I18n.t('Vendor Code (LTI 2):')}
                  name="developer_key[vendor_code]"
                  defaultValue={this.fieldValue('vendor_code')}
                />
                <TextInput
                  label={I18n.t('Icon URL:')}
                  name="developer_key[icon_url]"
                  defaultValue={this.fieldValue('icon_url')}
                />
                <TextArea
                  label={I18n.t('Notes:')}
                  name="developer_key[notes]"
                  defaultValue={this.fieldValue('notes')}
                  resize="both"
                />
                {this.renderTestClusterOnlyCheckbox()}
              </FormFieldGroup>
            </GridCol>
            <GridCol width={8}>
              <DeveloperKeyScopes
                availableScopes={this.props.availableScopes}
                availableScopesPending={this.props.availableScopesPending}
                developerKey={this.props.developerKey}
                requireScopes={this.state.requireScopes}
                onRequireScopesChange={this.handleRequireScopesChange}
                dispatch={this.props.dispatch}
                listDeveloperKeyScopesSet={this.props.listDeveloperKeyScopesSet}
              />
            </GridCol>
          </GridRow>
        </Grid>
      </form>
    )
  }
}

DeveloperKeyFormFields.defaultProps = {
  developerKey: {}
}

DeveloperKeyFormFields.propTypes = {
  dispatch: PropTypes.func.isRequired,
  listDeveloperKeyScopesSet: PropTypes.func.isRequired,
  developerKey: PropTypes.shape({
    notes: PropTypes.string,
    icon_url: PropTypes.string,
    vendor_code: PropTypes.string,
    redirect_uris: PropTypes.string,
    email: PropTypes.string,
    name: PropTypes.string,
    require_scopes: PropTypes.bool
  }),
  availableScopes: PropTypes.objectOf(PropTypes.arrayOf(
    PropTypes.shape({
      resource: PropTypes.string,
      scope: PropTypes.string
    })
  )).isRequired,
  availableScopesPending: PropTypes.bool.isRequired
}
