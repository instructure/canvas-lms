// eslint-disable-next-line @typescript-eslint/ban-ts-comment
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
import ReactDOM from 'react-dom'
import {useScope as createI18nScope} from '@canvas/i18n'
import authenticity_token from '@canvas/authenticity-token'
import CanvasModal from '@canvas/instui-bindings/react/Modal'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {checkStatus, defaultFetchOptions} from '@canvas/util/xhr'
import {Button} from '@instructure/ui-buttons'
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {Tooltip} from '@instructure/ui-tooltip'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import type {Event, Which} from './types'
import {subAssignmentOrOverride} from '@canvas/calendar/jquery/CommonEvent/SubAssignment'

const I18n = createI18nScope('calendar_event')

type Props = {
  readonly isOpen: boolean
  readonly onCancel: () => void
  readonly onDeleting: (which: Which) => void
  readonly onDeleted: (deletedEvents: [Event]) => void
  readonly onUpdated: (updatedEvents: [Event]) => void
  readonly delUrl: string
  readonly isRepeating: boolean
  readonly isSeriesHead: boolean
  readonly eventType: string
  readonly testIdPrefix?: string
}

const DeleteCalendarEventDialog = ({
  isOpen,
  onCancel,
  onDeleting,
  onDeleted,
  onUpdated,
  delUrl,
  isRepeating,
  isSeriesHead,
  eventType,
  testIdPrefix,
}: Props) => {
  const [which, setWhich] = useState<Which>('one')
  const [isDeleting, setIsDeleting] = useState<boolean>(false)

  const handleCancel = useCallback(
    (e = null) => {
      if (e?.code !== 'Escape' && e?.target.type === 'radio') {
        return
      }
      onCancel()
    },
    [onCancel],
  )

  const handleDelete = useCallback(() => {
    setIsDeleting(true)
    onDeleting(which)
    const defaultOptions = {...defaultFetchOptions()}
    defaultOptions.headers['Content-Type'] = 'application/json'
    fetch(delUrl, {
      method: 'DELETE',
      ...defaultOptions,
      body: JSON.stringify({
        which,
        authenticity_token: authenticity_token(),
      }),
    })
      .then(checkStatus)
      .then(res => res.json())
      .then(result => {
        setIsDeleting(false)
        const sortedEvents = {
          deleted: [],
          updated: [],
        }
        const returnedEvents = Array.isArray(result) ? result : [result]
        returnedEvents.reduce((runningResult, currentValue) => {
          if (currentValue.workflow_state === 'deleted') {
            runningResult.deleted.push(currentValue)
          } else {
            runningResult.updated.push(currentValue)
          }
          return runningResult
        }, sortedEvents)
        onDeleted(sortedEvents.deleted)
        if (sortedEvents.updated.length > 0) {
          onUpdated(sortedEvents.updated)
        }
      })
      .catch(_err => {
        setIsDeleting(false)
        showFlashAlert({message: I18n.t('Delete failed'), type: 'error'})
      })
  }, [delUrl, onDeleted, onDeleting, onUpdated, which])

  const renderFooter = useCallback((): JSX.Element => {
    const tiptext = I18n.t('Wait for delete to complete')
    return (
      <Flex as="section" justifyItems="end">
        <Tooltip renderTip={isDeleting && tiptext} on={isDeleting ? ['hover', 'focus'] : []}>
          <Button
            color="secondary"
            margin="0 small 0"
            onClick={() => isDeleting || handleCancel()}
            data-testid={`${testIdPrefix || ''}cancel-button`}
          >
            {I18n.t('Cancel')}
          </Button>
        </Tooltip>
        <Tooltip renderTip={isDeleting && tiptext} on={isDeleting ? ['hover', 'focus'] : []}>
          <Button
            color="danger"
            onClick={() => isDeleting || handleDelete()}
            data-testid={`${testIdPrefix || ''}delete-button`}
          >
            {isDeleting ? (
              <div style={{display: 'inline-block', margin: '-0.5rem 0.9rem'}}>
                <Spinner size="x-small" renderTitle={I18n.t('Deleting')} />
              </div>
            ) : (
              I18n.t('Delete')
            )}
          </Button>
        </Tooltip>
      </Flex>
    )
  }, [handleCancel, handleDelete, isDeleting, testIdPrefix])

  const renderRepeating = (): JSX.Element => {
    return (
      <RadioInputGroup
        name="which"
        defaultValue="one"
        description={I18n.t('Delete:')}
        onChange={(_event, value) => {
          setWhich(value)
        }}
      >
        <RadioInput
          value="one"
          label={I18n.t('This event')}
          data-testid={`${testIdPrefix || ''}this-event-radio`}
        />
        <RadioInput
          value="all"
          label={I18n.t('All events')}
          data-testid={`${testIdPrefix || ''}all-events-radio`}
        />
        {!isSeriesHead && (
          <RadioInput
            value="following"
            label={I18n.t('This and all following events')}
            data-testid={`${testIdPrefix || ''}following-events-radio`}
          />
        )}
      </RadioInputGroup>
    )
  }

  const renderOne = (): JSX.Element => {
    return (
      <Text>
        {eventType === 'assignment'
          ? I18n.t(
              'Are you sure you want to delete this event? Deleting this event will also delete the associated assignment.',
            )
          : subAssignmentOrOverride(eventType)
            ? I18n.t(
                'Are you sure you want to delete this event? Deleting this event will also delete the associated assignment and other checkpoints associated with the assignment.',
              )
            : I18n.t('Are you sure you want to delete this event?')}
      </Text>
    )
  }

  return (
    <CanvasModal
      open={isOpen}
      onDismiss={handleCancel}
      onSubmit={handleDelete}
      size="small"
      label={I18n.t('Confirm Deletion')}
      footer={renderFooter}
      data-testid={`${testIdPrefix || ''}dialog`}
    >
      <View as="div" margin="0 small" data-testid={`${testIdPrefix || ''}dialog-content`}>
        {isRepeating ? renderRepeating() : renderOne()}
      </View>
    </CanvasModal>
  )
}

function renderDeleteCalendarEventDialog(element: Element, props: Props): void {
  ReactDOM.render(<DeleteCalendarEventDialog {...props} />, element)
}

export {DeleteCalendarEventDialog, renderDeleteCalendarEventDialog}
