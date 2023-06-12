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
import {useScope as useI18nScope} from '@canvas/i18n'
import authenticity_token from '@canvas/authenticity-token'
import CanvasModal from '@canvas/instui-bindings/react/Modal'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {checkStatus, defaultFetchOptions} from '@instructure/js-utils'
import {Button} from '@instructure/ui-buttons'
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {Tooltip} from '@instructure/ui-tooltip'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'

const I18n = useI18nScope('calendar_event')

type Event = {
  id: string
  // a lot of other attributes that don't matter to me
}
type Which = 'one' | 'following' | 'all'

type Props = {
  readonly isOpen: boolean
  readonly onCancel: () => void
  readonly onDeleting: (which: Which) => void
  readonly onDeleted: (deletedEvents: [Event]) => void
  readonly delUrl: string
  readonly isRepeating: boolean
}
const DeleteCalendarEventDialog = ({
  isOpen,
  onCancel,
  onDeleting,
  onDeleted,
  delUrl,
  isRepeating,
}: Props) => {
  const [which, setWhich] = useState<Which>('one')
  const [isDeleting, setIsDeleting] = useState<boolean>(false)

  const handleCancel = useCallback(() => {
    onCancel()
  }, [onCancel])

  const handleDelete = useCallback(() => {
    setIsDeleting(true)
    onDeleting(which)
    const defaultOptions = {...defaultFetchOptions}
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
      .then(deletedEvents => {
        setIsDeleting(false)
        onDeleted(deletedEvents)
      })
      .catch(_err => {
        setIsDeleting(false)
        showFlashAlert({message: I18n.t('Delete failed'), type: 'error'})
      })
  }, [delUrl, onDeleted, onDeleting, which])

  const renderFooter = useCallback((): JSX.Element => {
    const tiptext = I18n.t('Wait for delete to complete')
    return (
      <Flex as="section" justifyItems="end">
        <Tooltip renderTip={isDeleting && tiptext} on={isDeleting ? ['hover', 'focus'] : []}>
          <Button color="secondary" margin="0 small 0" onClick={() => isDeleting || handleCancel()}>
            {I18n.t('Cancel')}
          </Button>
        </Tooltip>
        <Tooltip renderTip={isDeleting && tiptext} on={isDeleting ? ['hover', 'focus'] : []}>
          <Button color="primary" onClick={() => isDeleting || handleDelete()}>
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
  }, [handleCancel, handleDelete, isDeleting])

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
        <RadioInput value="one" label={I18n.t('This event')} />
        <RadioInput value="all" label={I18n.t('All events')} />
        <RadioInput value="following" label={I18n.t('This and all following events')} />
      </RadioInputGroup>
    )
  }

  const renderOne = (): JSX.Element => {
    return <Text>{I18n.t('Are you sure you want to delete this event?')}</Text>
  }

  return (
    <CanvasModal
      open={isOpen}
      onDismiss={handleCancel}
      onSubmit={handleDelete}
      size="small"
      label={I18n.t('Confirm Deletion')}
      footer={renderFooter}
    >
      <View as="div" margin="0 small">
        {isRepeating ? renderRepeating() : renderOne()}
      </View>
    </CanvasModal>
  )
}

function renderDeleteCalendarEventDialog(element: Element, props: Props): void {
  ReactDOM.render(<DeleteCalendarEventDialog {...props} />, element)
}

export {DeleteCalendarEventDialog, renderDeleteCalendarEventDialog}
