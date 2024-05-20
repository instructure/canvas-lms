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
import ReactDOM from 'react-dom'
import {useScope as useI18nScope} from '@canvas/i18n'
import CanvasModal from '@canvas/instui-bindings/react/Modal'
import {Button} from '@instructure/ui-buttons'
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import type {Which, CalendarEvent} from './types'

const I18n = useI18nScope('calendar_event')

type Props = {
  readonly event: CalendarEvent
  readonly isOpen: boolean
  readonly onUpdate?: (which: Which) => void
  readonly onCancel?: () => void
}

const UpdateCalendarEventDialog = ({event, isOpen, onUpdate, onCancel}: Props) => {
  const [which, setWhich] = useState<Which>('one')

  const handleCancel = useCallback(
    (e = null) => {
      if (e?.code !== 'Escape' && e?.target.type === 'radio') {
        return
      }
      onCancel?.()
    },
    [onCancel]
  )

  const handleSubmit = useCallback(() => {
    onUpdate?.(which)
  }, [onUpdate, which])

  const renderFooter = useCallback((): JSX.Element => {
    return (
      <Flex as="section" justifyItems="end">
        <Button color="secondary" margin="0 small 0" onClick={handleCancel}>
          {I18n.t('Cancel')}
        </Button>
        <Button color="primary" onClick={handleSubmit}>
          {I18n.t('Confirm')}
        </Button>
      </Flex>
    )
  }, [handleCancel, handleSubmit])

  return (
    <CanvasModal
      open={isOpen}
      onDismiss={handleCancel}
      onSubmit={handleSubmit}
      size="small"
      label={I18n.t('Confirm Changes')}
      footer={renderFooter}
    >
      <View as="div" margin="0 small">
        <RadioInputGroup
          name="which"
          defaultValue="one"
          description={I18n.t('Change:')}
          onChange={(_event, value: any) => setWhich(value)}
        >
          <RadioInput value="one" label={I18n.t('This event')} />
          <RadioInput value="all" label={I18n.t('All events')} />
          {!event.series_head && (
            <RadioInput value="following" label={I18n.t('This and all following events')} />
          )}
        </RadioInputGroup>
      </View>
    </CanvasModal>
  )
}

const renderUpdateCalendarEventDialog = (selectedEvent: CalendarEvent) => {
  let modalContainer = document.getElementById('update_modal_container')
  if (!modalContainer) {
    modalContainer = document.createElement('div')
    modalContainer.id = 'update_modal_container'
    document.body.appendChild(modalContainer)
  }

  const whichPromise = new Promise(resolve => {
    ReactDOM.render(
      <UpdateCalendarEventDialog
        event={selectedEvent}
        isOpen={true}
        onCancel={() => {
          ReactDOM.unmountComponentAtNode(modalContainer as HTMLElement)
          resolve(undefined)
        }}
        onUpdate={which => {
          ReactDOM.unmountComponentAtNode(modalContainer as HTMLElement)
          resolve(which)
        }}
      />,
      modalContainer as HTMLElement
    )
  })
  return whichPromise
}

export {UpdateCalendarEventDialog, renderUpdateCalendarEventDialog}
