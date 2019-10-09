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

import I18n from 'i18n!assignments_2_url_entry'
import React from 'react'

import {Billboard} from '@instructure/ui-billboard'
import {Button} from '@instructure/ui-buttons'
import {Flex, View} from '@instructure/ui-layout'
import {IconEyeLine, IconLinkLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y'
import {TextInput} from '@instructure/ui-text-input'

class UrlEntry extends React.Component {
  state = {
    value: '',
    messages: [],
    displayPreviewIcon: false
  }

  componentDidMount() {
    window.addEventListener('beforeunload', this.beforeunload)
  }

  componentWillUnmount() {
    window.removeEventListener('beforeunload', this.beforeunload)
  }

  // Warn the user if they are attempting to leave the page with an unsubmitted url entry
  beforeunload = e => {
    if (this.state.value) {
      e.preventDefault()
      e.returnValue = true
    }
  }

  handleChange = e => {
    this.setState({
      value: e.target.value,
      messages: e.target.validity.valid
        ? []
        : [{text: I18n.t('Please enter a url'), type: 'error'}],
      displayPreviewIcon: e.target.validity.valid && e.target.value
    })
  }

  renderURLInput = () => {
    const inputStyle = {
      maxWidth: '600px',
      marginLeft: 'auto',
      marginRight: 'auto'
    }

    return (
      <div style={inputStyle}>
        <Flex justifyItems="center">
          <Flex.Item grow>
            <TextInput
              renderLabel={<ScreenReaderContent>{I18n.t('Website url input')}</ScreenReaderContent>}
              type="url"
              placeholder={I18n.t('Paste URL')}
              value={this.state.value}
              onChange={this.handleChange}
              messages={this.state.messages}
            />
          </Flex.Item>
          <Flex.Item>
            {this.state.displayPreviewIcon && (
              <Button
                icon={IconEyeLine}
                margin="0 0 0 x-small"
                onClick={() => window.open(this.state.value)}
                data-testid="preview-button"
              >
                <ScreenReaderContent>{I18n.t('Preview website url')}</ScreenReaderContent>
              </Button>
            )}
          </Flex.Item>
        </Flex>
      </div>
    )
  }

  render() {
    return (
      <View as="div" borderWidth="small" data-testid="url-entry">
        <Billboard
          heading={I18n.t('Website Url')}
          hero={<IconLinkLine color="brand" />}
          message={this.renderURLInput()}
        />
      </View>
    )
  }
}

export default UrlEntry
