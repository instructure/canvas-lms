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

import {useScope as useI18nScope} from '@canvas/i18n'
import React, {useState} from 'react'
import CanvasModal from '@canvas/instui-bindings/react/Modal'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {Button} from '@instructure/ui-buttons'
import {IconUnpublishedSolid, IconCompleteSolid, IconCalendarMonthLine} from '@instructure/ui-icons'
import {DateTime} from '@instructure/ui-i18n'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import {Alert} from '@instructure/ui-alerts'
import CanvasDateInput from '@canvas/datetime/react/components/DateInput'
import useDateTimeFormat from '@canvas/use-date-time-format-hook'
import doFetchApi from '@canvas/do-fetch-api-effect'

const I18n = useI18nScope('publish_btn_module')

export default function DelayedPublishDialog({
  name,
  courseId,
  contentId,
  publishAt,
  onPublish,
  onUpdatePublishAt,
  onClose,
  timeZone,
}) {
  const [open, setOpen] = useState(true)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)
  const [selectedDate, setSelectedDate] = useState(publishAt)
  const [publishState, setPublishState] = useState('scheduled')

  const changePublishAt = newDate => {
    setError(null)
    setLoading(true)
    doFetchApi({
      method: 'PUT',
      path: `/api/v1/courses/${courseId}/pages/${contentId}`,
      params: {wiki_page: {publish_at: newDate}},
    })
      .then(() => {
        setOpen(false)
        onUpdatePublishAt(newDate)
        onClose()
      })
      .catch(_error => {
        setLoading(false)
        setError(true)
      })
  }

  const onSubmit = e => {
    e.stopPropagation()
    e.preventDefault()
    switch (publishState) {
      case 'published':
        setOpen(false)
        onPublish()
        onClose()
        break
      case 'unpublished':
        changePublishAt(null)
        break
      case 'scheduled':
        changePublishAt(selectedDate)
        break
    }
  }

  function Footer() {
    return (
      <>
        {loading && <Spinner renderTitle={I18n.t('Updating publication date')} />}
        <Button
          interaction={loading ? 'disabled' : 'enabled'}
          onClick={onClose}
          margin="0 x-small 0 0"
        >
          {I18n.t('Cancel')}
        </Button>
        <Button interaction={loading ? 'disabled' : 'enabled'} color="primary" type="submit">
          {I18n.t('OK')}
        </Button>
      </>
    )
  }

  const tz = timeZone || ENV?.TIMEZONE || DateTime.browserTimeZone()
  const formatDate = useDateTimeFormat('date.formats.full_with_weekday', tz)

  return (
    <CanvasModal
      as="form"
      padding="large"
      open={open}
      onDismiss={onClose}
      onSubmit={onSubmit}
      label={I18n.t('Publication Options')}
      shouldCloseOnDocumentClick={false}
      footer={<Footer />}
    >
      {error && <Alert variant="error">{I18n.t('Failed to update publication date')}</Alert>}
      <RadioInputGroup
        onChange={(_, val) => setPublishState(val)}
        name="publish_state"
        defaultValue={publishState}
        description={I18n.t('Options for %{name}', {name})}
      >
        <RadioInput
          key="published"
          value="published"
          label={
            <>
              <IconCompleteSolid color="success" /> {I18n.t('Published')}
            </>
          }
        />
        <RadioInput
          key="unpublished"
          value="unpublished"
          label={
            <>
              <IconUnpublishedSolid /> {I18n.t('Unpublished')}
            </>
          }
        />
        <RadioInput
          key="scheduled"
          value="scheduled"
          label={
            <>
              <IconCalendarMonthLine color="warning" /> {I18n.t('Scheduled for publication')}
            </>
          }
        />
        <View as="div" padding="0 0 0 large">
          <CanvasDateInput
            timezone={tz}
            selectedDate={selectedDate}
            formatDate={formatDate}
            width="17rem"
            onSelectedDateChange={date => setSelectedDate(date.toISOString())}
          />
        </View>
      </RadioInputGroup>
    </CanvasModal>
  )
}
