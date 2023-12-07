/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {useCallback, useEffect, useState} from 'react'
import {CloseButton, Button} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {TextInput} from '@instructure/ui-text-input'
import {Tooltip} from '@instructure/ui-tooltip'
import {View} from '@instructure/ui-view'

export type CreateModalProps = {
  objectType: string
  objectId: string
  mode: 'create' | 'rename'
  currentName?: string
  open: boolean
  onDismiss: () => void
  onSubmit: (f: HTMLFormElement) => void
}

const NamingModal = ({
  objectType,
  objectId,
  mode,
  currentName,
  open,
  onDismiss,
  onSubmit,
}: CreateModalProps) => {
  const [name, setName] = useState(currentName ?? '')

  useEffect(() => {
    setName(currentName ?? '')
  }, [currentName])

  const handleNameChange = useCallback((_e: React.ChangeEvent<HTMLInputElement>, value: string) => {
    setName(value)
  }, [])

  const handleSubmit = useCallback(
    (e: React.UIEvent) => {
      e.preventDefault()
      if (!name.trim()) return
      onSubmit(document.getElementById('create_form') as HTMLFormElement)
    },
    [name, onSubmit]
  )

  const renderTitle = () => {
    switch (mode) {
      case 'create':
        return `Create ${objectType}`
      case 'rename':
        return `Rename ${objectType}`
    }
  }

  return (
    <Modal open={open} size="auto" label={`Create ${objectType}`} onDismiss={onDismiss}>
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="medium"
          onClick={onDismiss}
          screenReaderLabel="Close"
        />
        <Heading>{renderTitle()}</Heading>
      </Modal.Header>
      <Modal.Body>
        {/* @ts-expect-error */}
        <form id="create_form" action={mode} onSubmit={handleSubmit}>
          <input type="hidden" name="userId" value={ENV.current_user.id} />
          <input type="hidden" name="id" value={objectId} />
          <View as="div" minWidth="700px">
            <TextInput
              name="title"
              placeholder={`Enter ${objectType.toLowerCase()} name`}
              renderLabel={`${objectType} Name`}
              onChange={handleNameChange}
              value={name}
            />
          </View>
        </form>
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={onDismiss}>Cancel</Button>
        <Tooltip
          renderTip="You must provide a name"
          on={name.trim() ? [] : ['click', 'hover', 'focus']}
        >
          {/* @ts-expect-error */}
          <Button color="primary" margin="0 0 0 small" onClick={handleSubmit}>
            Save
          </Button>
        </Tooltip>
      </Modal.Footer>
    </Modal>
  )
}

export default NamingModal
