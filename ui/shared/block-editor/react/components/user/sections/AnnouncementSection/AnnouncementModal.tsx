/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {useCallback, useEffect, useRef, useState} from 'react'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {type Announcement, announcements} from '../../../../assets/data/announcements'

type AnnouncementModalProps = {
  open: boolean
  currentAnnouncementId: string | undefined
  onClose: () => void
  onSelect: (questionId: string) => void
}

const AnnouncementModal = ({
  open,
  currentAnnouncementId,
  onClose,
  onSelect,
}: AnnouncementModalProps) => {
  const [announcementId, setAnnouncementId] = useState<string | undefined>(currentAnnouncementId)
  const parser = useRef(new DOMParser())

  useEffect(() => {
    if (!announcementId && announcements.length > 0) {
      setAnnouncementId(announcements[0].id)
    }
  }, [announcementId])

  const handleAnnouncementChange = useCallback(
    (
      _event: React.SyntheticEvent,
      data: {
        value?: string | number
        id?: string
      }
    ) => {
      setAnnouncementId(data.value as string)
    },
    []
  )

  const handleChooseAnnouncement = useCallback(() => {
    if (!announcementId) return
    onSelect(announcementId)
    onClose()
  }, [onClose, onSelect, announcementId])

  return (
    <Modal open={open} label="Select an announcement" onDismiss={onClose}>
      <Modal.Header>
        <Heading>Select an announcement</Heading>
        <CloseButton placement="end" onClick={onClose} screenReaderLabel="Close" />
      </Modal.Header>
      <Modal.Body>
        <SimpleSelect
          renderLabel="Select an announcement"
          assistiveText="Use arrow keys to navigate options"
          onChange={handleAnnouncementChange}
          value={announcementId}
        >
          {announcements.map((announcement: Announcement) => {
            const atitledoc = parser.current.parseFromString(announcement.title, 'text/html')
            return (
              <SimpleSelect.Option
                id={announcement.id}
                key={announcement.id}
                value={announcement.id}
              >
                {atitledoc.body.textContent as string}
              </SimpleSelect.Option>
            )
          })}
        </SimpleSelect>
      </Modal.Body>
      <Modal.Footer>
        <Button color="secondary" onClick={onClose}>
          Cancel
        </Button>
        <Button
          onClick={handleChooseAnnouncement}
          color="primary"
          interaction={announcementId ? 'enabled' : 'disabled'}
          margin="0 0 0 x-small"
        >
          Add to Section
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export {AnnouncementModal}
