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

import React, {useState} from 'react'
import {bool, func, shape, string} from 'prop-types'
import {Button, CloseButton} from '@instructure/ui-buttons'

import {Heading} from '@instructure/ui-heading'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {TextInput} from '@instructure/ui-text-input'
import {Flex} from '@instructure/ui-flex'
import {Tray} from '@instructure/ui-tray'

import formatMessage from '../../../../format-message'

export default function EmbedOptionsTray(props) {
  const {content} = props

  const [text, setText] = useState(content.text)
  const [link, setLink] = useState(content.url)
  const [displayAs, setDisplayAs] = useState(content.displayAs)

  function handleSave(event) {
    event.preventDefault()
    props.onSave({displayAs, text, url: link})
  }

  function handleTextChange(event) {
    setText(event.target.value)
  }

  function handleLinkChange(event) {
    setLink(event.target.value)
  }

  function handleDisplayAsChange(event) {
    setDisplayAs(event.target.value)
  }

  return (
    <Tray
      label={formatMessage('Embed Options Tray')}
      onDismiss={props.onRequestClose}
      onEntered={props.onEntered}
      onExited={props.onExited}
      open={props.open}
      placement="end"
      shouldCloseOnDocumentClick
      shouldContainFocus
      shouldReturnFocus
    >
      <Flex direction="column" height="100vh">
        <Flex.Item as="header" padding="medium">
          <Flex direction="row">
            <Flex.Item grow shrink>
              <Heading as="h2">{formatMessage('Options')}</Heading>
            </Flex.Item>

            <Flex.Item>
              <CloseButton onClick={props.onRequestClose}>{formatMessage('Close')}</CloseButton>
            </Flex.Item>
          </Flex>
        </Flex.Item>

        <Flex.Item as="form" grow margin="none" shrink>
          <Flex justifyItems="space-between" direction="column" height="100%">
            <Flex.Item grow padding="small" shrink>
              <Flex direction="column">
                <Flex.Item padding="small">
                  <TextInput
                    renderLabel={formatMessage('Text')}
                    onChange={handleTextChange}
                    value={text}
                  />
                </Flex.Item>

                <Flex.Item padding="small">
                  <TextInput
                    renderLabel={formatMessage('Link')}
                    onChange={handleLinkChange}
                    value={link}
                  />
                </Flex.Item>

                <Flex.Item margin="small none none none" padding="small">
                  <RadioInputGroup
                    description={formatMessage('Display Options')}
                    name="display-content-as"
                    onChange={handleDisplayAsChange}
                    value={displayAs}
                  >
                    <RadioInput label={formatMessage('Embed Preview')} value="embed" />

                    <RadioInput
                      label={formatMessage('Display Text Link (Opens in a new tab)')}
                      value="link"
                    />
                  </RadioInputGroup>
                </Flex.Item>
              </Flex>
            </Flex.Item>

            <Flex.Item
              background="light"
              borderWidth="small none none none"
              padding="small medium"
              textAlign="end"
            >
              <Button disabled={text === '' || link === ''} onClick={handleSave} variant="primary">
                {formatMessage('Done')}
              </Button>
            </Flex.Item>
          </Flex>
        </Flex.Item>
      </Flex>
    </Tray>
  )
}

EmbedOptionsTray.propTypes = {
  content: shape({
    text: string.isRequired,
    url: string.isRequired
  }).isRequired,
  onEntered: func,
  onExited: func,
  onRequestClose: func.isRequired,
  onSave: func.isRequired,
  open: bool.isRequired
}

EmbedOptionsTray.defaultProps = {
  onEntered: null,
  onExited: null
}
