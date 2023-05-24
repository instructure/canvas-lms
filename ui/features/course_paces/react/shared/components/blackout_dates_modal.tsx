// @ts-nocheck
/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import React, {useCallback, useState} from 'react'

import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {View} from '@instructure/ui-view'

import {useScope as useI18nScope} from '@canvas/i18n'

import {BlackoutDate} from '../types'
import BlackoutDates from './blackout_dates'

const I18n = useI18nScope('course_paces_blackout_dates_modal')

interface PassedProps {
  readonly open: boolean
  readonly blackoutDates: BlackoutDate[]
  readonly onCancel: () => any
  readonly onSave: (blackoutDates: BlackoutDate[]) => any
}

const BlackoutDatesModal = ({open, blackoutDates, onCancel, onSave}: PassedProps) => {
  const [updatedBlackoutDates, setUpdatedBlackoutDates] = useState(blackoutDates)

  const handleChange = useCallback((newBlackoutDates: BlackoutDate[]): void => {
    setUpdatedBlackoutDates(newBlackoutDates)
  }, [])

  const handleSave = useCallback((): void => {
    onSave(updatedBlackoutDates)
  }, [updatedBlackoutDates, onSave])

  return (
    <Modal open={open} onDismiss={onCancel} label={I18n.t('Blackout Dates')} size="auto">
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="medium"
          color="primary"
          onClick={onCancel}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>Blackout Dates</Heading>
      </Modal.Header>

      <Modal.Body>
        <View as="div" width="36rem">
          <BlackoutDates blackoutDates={updatedBlackoutDates} onChange={handleChange} />
        </View>
      </Modal.Body>

      <Modal.Footer>
        <Button color="secondary" onClick={onCancel}>
          {I18n.t('Cancel')}
        </Button>
        <Button
          margin="0 0 0 x-small"
          color="primary"
          onClick={() => {
            handleSave()
          }}
        >
          {I18n.t('Save')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export default BlackoutDatesModal
