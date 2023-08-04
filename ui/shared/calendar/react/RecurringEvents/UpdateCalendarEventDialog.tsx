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
// @ts-expect-error
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import {Spinner} from '@instructure/ui-spinner'
// @ts-expect-error
import {Tooltip} from '@instructure/ui-tooltip'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {Which, CalendarEvent} from './types'

const I18n = useI18nScope('calendar_event')

type Props = {
  readonly event: CalendarEvent
  readonly params: object
  readonly isOpen: boolean
  readonly onUpdate?: (which: Which) => void
  readonly onCancel?: () => void
  readonly onUpdated?: (updatedEvents: [Event], which: Which) => void
  readonly onError?: (response: any, which: Which) => void
}

const UpdateCalendarEventDialog = ({
  event,
  params,
  isOpen,
  onUpdate,
  onCancel,
  onUpdated,
  onError,
}: Props) => {
  const [which, setWhich] = useState<Which>('one')
  const [isUpdating, setIsUpdating] = useState<boolean>(false)

  const handleCancel = useCallback(() => {
    onCancel?.()
  }, [onCancel])

  const handleSubmit = useCallback(() => {
    setIsUpdating(true)
    onUpdate?.(which)

    const handleSuccess = (data: any) => {
      setIsUpdating(false)
      onUpdated?.(data, which)
    }

    const handleError = (response: any) => {
      setIsUpdating(false)
      onError?.(response, which)
    }
    const requestParams = {...params, which}

    doFetchApi({
      path: event.url,
      method: 'PUT',
      params: requestParams,
    })
      .then(handleSuccess)
      .catch(handleError)
  }, [event, params, onUpdate, onUpdated, onError, which])

  const renderFooter = useCallback((): JSX.Element => {
    const tipText = I18n.t('Wait for update to complete')
    return (
      <Flex as="section" justifyItems="end">
        <Tooltip renderTip={isUpdating && tipText} on={isUpdating ? ['hover', 'focus'] : []}>
          <Button color="secondary" margin="0 small 0" onClick={() => isUpdating || handleCancel()}>
            {I18n.t('Cancel')}
          </Button>
        </Tooltip>
        <Tooltip renderTip={isUpdating && tipText} on={isUpdating ? ['hover', 'focus'] : []}>
          <Button color="primary" onClick={() => isUpdating || handleSubmit()}>
            {isUpdating ? (
              <div style={{display: 'inline-block', margin: '-0.5rem 0.9rem'}}>
                <Spinner size="x-small" renderTitle={I18n.t('Updating')} />
              </div>
            ) : (
              I18n.t('Confirm')
            )}
          </Button>
        </Tooltip>
      </Flex>
    )
  }, [handleCancel, handleSubmit, isUpdating])

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
          onChange={(_event: Event, value: Which) => setWhich(value)}
        >
          <RadioInput value="one" label={I18n.t('This event')} />
          {event.series_head && <RadioInput value="all" label={I18n.t('All events')} />}
          <RadioInput value="following" label={I18n.t('This and all following events')} />
        </RadioInputGroup>
      </View>
    </CanvasModal>
  )
}

function renderUpdateCalendarEventDialog(element: Element, props: Props): void {
  ReactDOM.render(<UpdateCalendarEventDialog {...props} />, element)
}

export {UpdateCalendarEventDialog, renderUpdateCalendarEventDialog}
