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
import { CheckboxGroup } from '@instructure/ui-forms'
import FormFieldGroup from '@instructure/ui-form-field/lib/components/FormFieldGroup';
import TextInput from '@instructure/ui-forms/lib/components/TextInput';
import TextArea from '@instructure/ui-forms/lib/components/TextArea';
import Checkbox from '@instructure/ui-forms/lib/components/Checkbox';
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent';

export default class ManualConfigurationForm extends React.Component {
  state = {
    toolConfiguration: {}
  }

  get toolConfiguration() {
    return this.state.toolConfiguration
  }

  render() {
    const { toolConfiguration } = this.state;
    const { validScopes } = this.props;
    return (
      <View>
        <FormFieldGroup
          description={I18n.t('Manual Configuration')}
          layout="stacked"
        >
          <FormFieldGroup
            description={<ScreenReaderContent>{I18n.t("Display Values")}</ScreenReaderContent>}
            layout="columns"
          >
            <TextInput
              name="title"
              value={toolConfiguration.title}
              label={I18n.t("Title")}
              required
            />
            <TextInput
              name="icon_url"
              value={toolConfiguration.title}
              label={I18n.t("Icon Url")}
            />
          </FormFieldGroup>
          <TextArea
            name="description"
            value={toolConfiguration.description}
            label={I18n.t("Description")}
            maxHeight="5rem"
            required
          />
          <FormFieldGroup
            description={<ScreenReaderContent>{I18n.t("OIDC Values")}</ScreenReaderContent>}
            layout="columns"
          >
            <TextInput
              name="target_link_uri"
              value={toolConfiguration.target_link_uri}
              label={I18n.t("Target Link URI")}
              required
            />
            <TextInput
              name="oidc_initiation_url"
              value={toolConfiguration.oidc_initiation_url}
              label={I18n.t("OpenID Connect Initiation Url")}
              required
            />
          </FormFieldGroup>
          <TextArea
            name="public_jwk"
            value={toolConfiguration.public_jwk}
            label={I18n.t("Public JWK")}
            maxHeight="10rem"
            required
            resize="vertical"
            autoGrow
          />
          <CheckboxGroup
            name="services"
            onChange={() => {}}
            value={toolConfiguration.scopes}
            description={I18n.t("LTI Advantage Services to enable")}
          >
            {
              Object.keys(validScopes).map(key => {
                return <Checkbox
                  key={key}
                  label={validScopes[key]}
                  value={key}
                  variant="toggle"
                />
              })
            }
          </CheckboxGroup>
        </FormFieldGroup>
      </View>
    )
  }
}

ManualConfigurationForm.propTypes = {
  validScopes: PropTypes.object.isRequired,
  validPlacements: PropTypes.arrayOf(PropTypes.string).isRequired
}
