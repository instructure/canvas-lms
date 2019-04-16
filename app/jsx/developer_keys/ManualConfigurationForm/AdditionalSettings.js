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
import FormFieldGroup from '@instructure/ui-form-field/lib/components/FormFieldGroup';
import TextInput from '@instructure/ui-forms/lib/components/TextInput';
import TextArea from '@instructure/ui-forms/lib/components/TextArea';
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent';
import { ToggleDetails } from '@instructure/ui-toggle-details';


export default class AdditionalSettings extends React.Component {
  constructor (props) {
    super(props);
    this.state = {
      additionalSettings: this.props.additionalSettings,
      custom_fields: this.props.custom_fields
    }
  }

  generateToolConfigurationPart = () => {
    return this.state.toolConfiguration
  }

  render() {
    const { additionalSettings, custom_fields } = this.state;

    return (
      <ToggleDetails
        summary={I18n.t("Additional Settings")}
        fluidWidth
      >
        <View
          as="div"
          margin="small"
        >
          <FormFieldGroup
            description={<ScreenReaderContent>{I18n.t("Identification Values")}</ScreenReaderContent>}
            layout="columns"
          >
            <TextInput
              name="domain"
              value={additionalSettings.domain}
              label={I18n.t("Domain")}
            />
            <TextInput
              name="tool_id"
              value={additionalSettings.tool_id}
              label={I18n.t("Tool Id")}
            />
          </FormFieldGroup>
          <FormFieldGroup
            description={<ScreenReaderContent>{I18n.t("Display Values")}</ScreenReaderContent>}
            layout="columns"
          >
            <TextInput
              name="settings_icon_url"
              value={additionalSettings.icon_url}
              label={I18n.t("Icon Url")}
            />
            <TextInput
              name="text"
              value={additionalSettings.text}
              label={I18n.t("Text")}
            />
            <TextInput
              name="selection_height"
              value={additionalSettings.selection_height}
              label={I18n.t("Selection Height")}
            />
            <TextInput
              name="selection_width"
              value={additionalSettings.selection_width}
              label={I18n.t("Selection Width")}
            />
          </FormFieldGroup>
          <TextArea
            label={I18n.t('Custom Fields')}
            maxHeight="10rem"
            messages={[{text: I18n.t('One per line. Format: name=value'), type: 'hint'}]}
            name="custom_fields"
            value={Object.keys(custom_fields).map(k => `${k}=${custom_fields[k]}`).join("\n")}
          />
        </View>
      </ToggleDetails>
    )
  }
}

AdditionalSettings.propTypes = {
  additionalSettings: PropTypes.shape({
    domain: PropTypes.string,
    tool_id: PropTypes.string,
    icon_url: PropTypes.string,
    text: PropTypes.string,
    selection_height: PropTypes.number,
    selection_width: PropTypes.number
  }),
  custom_fields: PropTypes.object
}

AdditionalSettings.defaultProps = {
  additionalSettings: {
    domain: '',
    tool_id: '',
    icon_url: '',
    text: '',
    selection_height: null,
    selection_width: null
  },
  custom_fields: {}
}
