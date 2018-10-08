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

import Heading from '@instructure/ui-elements/lib/components/Heading'
import Select from '@instructure/ui-forms/lib/components/Select'
import TextArea from '@instructure/ui-forms/lib/components/TextArea'
import TextInput from '@instructure/ui-forms/lib/components/TextInput'
import View from '@instructure/ui-layout/lib/components/View'

export default class ToolConfigurationForm extends React.Component {
  state = {
    configurationType: 'json'
  }

  get toolConfiguration() {
    const {toolConfiguration} = this.props
    return toolConfiguration ? JSON.stringify(toolConfiguration) : ''
  }

  handleConfigTypeChange = (e, option) => {
    this.setState({
      configurationType: option.value
    })
  }

  configurationInput() {
    if (this.state.configurationType === 'json') {
      return (
        <TextArea
          name="tool_configuration"
          defaultValue={this.toolConfiguration}
          label={I18n.t('LTI 1.3 Configuration')}
          maxHeight="20rem"
        />
      )
    }
    return (
      <TextInput
        name="tool_configuration_url"
        defaultValue={this.props.toolConfigurationUrl}
        label={I18n.t('JSON URL')}
      />
    )
  }

  render() {
    return (
      <View>
        <Heading level="h2" as="h2" margin="0 0 x-small">
          {I18n.t('Configure')}
        </Heading>
        <Select
          label="Medium"
          assistiveText={I18n.t('2 options available. Use arrow keys to navigate options.')}
          onChange={this.handleConfigTypeChange}
        >
          <option value="json">{I18n.t('Paste JSON')}</option>
          <option value="url">{I18n.t('Enter URL')}</option>
        </Select>
        <br />
        {this.configurationInput()}
      </View>
    )
  }
}

ToolConfigurationForm.propTypes = {
  toolConfiguration: PropTypes.object.isRequired,
  toolConfigurationUrl: PropTypes.string.isRequired
}
