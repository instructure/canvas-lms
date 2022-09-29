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

import React from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {TextInput} from '@instructure/ui-text-input'
import {IconLtiLine} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('external_tools')

class ConfigurationFormLti13 extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      messages: [],
      clientId: '',
    }
  }

  setClientId = event => {
    const clientId = event.currentTarget.value

    this.setState({
      clientId,
      messages: this.messages({clientId}),
    })
  }

  getFormData() {
    return {
      client_id: this.state.clientId,
    }
  }

  isValid() {
    const {clientId} = this.state
    this.setState({
      messages: this.messages({clientId}),
    })
    return !!this.state.clientId
  }

  messages(nextState) {
    const {clientId} = nextState
    return clientId ? [] : [{text: I18n.t('Client ID is required'), type: 'error'}]
  }

  render() {
    return (
      <View as="div" margin="0 0 small 0">
        <TextInput
          name="client_id"
          value={this.state.clientId}
          renderLabel={I18n.t('Client ID')}
          renderAfterInput={() => <IconLtiLine />}
          ref={this.clientIdInput}
          onChange={this.setClientId}
          messages={[
            {
              text: I18n.t(
                'To obtain a client ID, an account admin will need to generate an LTI developer key.'
              ),
              type: 'hint',
            },
          ].concat(this.state.messages)}
          isRequired={true}
        />
      </View>
    )
  }
}

export default ConfigurationFormLti13
