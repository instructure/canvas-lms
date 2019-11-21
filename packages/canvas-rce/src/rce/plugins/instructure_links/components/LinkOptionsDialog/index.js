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
import {bool, func, oneOf, string} from 'prop-types'
import {Button, CloseButton} from '@instructure/ui-buttons'

import {Heading} from '@instructure/ui-elements'
import {TextInput} from '@instructure/ui-text-input'
import {Modal} from '@instructure/ui-overlays'
import {View} from '@instructure/ui-layout'

import formatMessage from '../../../../../format-message'

const CREATE_LINK = 'create'
const EDIT_LINK = 'edit'

export default function LinkOptionsDialog(props) {
  const [text, setText] = useState(props.text || '')
  const [url, setUrl] = useState(props.url || '')

  function handleSave(event) {
    event.preventDefault()
    if (!url) return
    const linkText = text.trim() || url
    props.onSave({
      text: linkText,
      target: '_blank',
      href: url
    })
  }

  function handleTextChange(event) {
    setText(event.target.value)
  }

  function handleLinkChange(event) {
    setUrl(event.target.value)
  }

  const label =
    props.operation === CREATE_LINK ? formatMessage('Insert Link') : formatMessage('Edit Link')

  return (
    <Modal
      data-testid="RCELinkOptionsDialog"
      data-mce-component
      as="form"
      label={label}
      onDismiss={props.onRequestClose}
      onEntered={props.onEntered}
      onExited={props.onExited}
      onSubmit={handleSave}
      open={props.open}
      shouldCloseOnDocumentClick
      shouldReturnFocus={false}
      size="medium"
    >
      <Modal.Header>
        <CloseButton offset="medium" placement="end" variant="icon" onClick={props.onRequestClose}>
          {formatMessage('Close')}
        </CloseButton>
        <Heading>{label}</Heading>
      </Modal.Header>

      <Modal.Body>
        <View as="div" margin="small">
          <TextInput
            renderLabel={formatMessage('Text')}
            name="linktext"
            onChange={handleTextChange}
            value={text}
          />
        </View>
        <View as="div" margin="small">
          <TextInput
            renderLabel={formatMessage('Link')}
            name="linklink"
            onChange={handleLinkChange}
            value={url}
          />
        </View>
      </Modal.Body>

      <Modal.Footer>
        <input type="submit" style={{display: 'none'}} />
        <Button variant="default" onClick={props.onRequestClose} margin="0 small">
          {formatMessage('Close')}
        </Button>
        <Button disabled={!url} onClick={handleSave} variant="primary">
          {formatMessage('Done')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

LinkOptionsDialog.propTypes = {
  text: string,
  url: string,
  operation: oneOf([CREATE_LINK, EDIT_LINK]),
  onEntered: func,
  onExited: func,
  onRequestClose: func.isRequired,
  onSave: func.isRequired,
  open: bool.isRequired
}

LinkOptionsDialog.defaultProps = {
  onEntered: null,
  onExited: null
}
