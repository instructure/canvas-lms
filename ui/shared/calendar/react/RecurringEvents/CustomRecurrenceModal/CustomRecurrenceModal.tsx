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
import CanvasModal from '@canvas/instui-bindings/react/Modal'
import {useScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import CustomRecurrence from '../CustomRecurrence/CustomRecurrence'
import RRuleHelper, {type RRuleHelperSpec} from '../RRuleHelper'

const I18n = useScope('calendar_custom_recurring_event_custom_recurrence_modal')

const isValid = (spec: RRuleHelperSpec): boolean => {
  const rrule = new RRuleHelper(spec)
  try {
    return rrule.isValid()
  } catch (_e) {
    return false
  }
}

type CustomRecurrenceErrorState = {
  hasError: boolean
  errorMessage: string
}

class CustomRecurrenceErrorBoundary extends React.Component {
  state: CustomRecurrenceErrorState

  constructor(props: any) {
    super(props)
    this.state = {
      hasError: false,
      errorMessage: '',
    }
  }

  static getDerivedStateFromError(error: Error) {
    return {
      hasError: true,
      errorMessage: error.message,
    }
  }

  render() {
    if (this.state.hasError) {
      return (
        <div>
          <p>{I18n.t('There was an error loading the Custom Repeating Event editor')}</p>
          <p>{this.state.errorMessage}</p>
        </div>
      )
    }
    return this.props.children
  }
}

type FooterProps = {
  canSave: boolean
  onDismiss: () => void
  onSave: () => void
}

const Footer = ({canSave, onDismiss, onSave}: FooterProps) => {
  return (
    <>
      <Button onClick={onDismiss}>{I18n.t('Cancel')}</Button>
      <Button
        interaction={canSave ? 'enabled' : 'disabled'}
        type="submit"
        color="primary"
        margin="0 0 0 x-small"
        onClick={onSave}
      >
        {I18n.t('Done')}
      </Button>
    </>
  )
}

export type CustomRecurrenceModalProps = {
  eventStart: string
  locale: string
  timezone: string
  courseEndAt?: string
  RRULE: string
  isOpen: boolean
  onClose: () => void
  onDismiss: () => void
  onSave: (RRULE: string) => void
}

export default function CustomRecurrenceModal({
  eventStart,
  locale,
  timezone,
  courseEndAt,
  RRULE,
  isOpen,
  onClose,
  onDismiss,
  onSave,
}: CustomRecurrenceModalProps) {
  const [currSpec, setCurrSpec] = useState<RRuleHelperSpec>(() => {
    return RRuleHelper.parseString(RRULE)
  })
  const [isValidState, setIsValidState] = useState<boolean>(() => isValid(currSpec))

  useEffect(() => {
    setCurrSpec(RRuleHelper.parseString(RRULE))
  }, [RRULE])
  useEffect(() => {
    setIsValidState(isValid(currSpec))
  }, [currSpec])

  const handleChange = useCallback((newSpec: RRuleHelperSpec) => {
    setCurrSpec(newSpec)
  }, [])

  const handleSave = useCallback(() => {
    const rrule = new RRuleHelper(currSpec).toString()
    onSave(rrule)
  }, [currSpec, onSave])

  return (
    <CanvasModal
      id="custom-repeating-event-modal"
      label={I18n.t('Custom Repeating Event')}
      onClose={onClose}
      onDismiss={onDismiss}
      open={isOpen}
      padding="small medium"
      footer={<Footer canSave={isValidState} onDismiss={onDismiss} onSave={handleSave} />}
      shouldCloseOnDocumentClick={false}
    >
      <div style={{minWidth: '28rem', minHeight: '21rem'}}>
        <CustomRecurrenceErrorBoundary>
          <CustomRecurrence
            eventStart={eventStart}
            locale={locale}
            timezone={timezone}
            courseEndAt={courseEndAt}
            rruleSpec={currSpec}
            onChange={handleChange}
          />
        </CustomRecurrenceErrorBoundary>
      </div>
    </CanvasModal>
  )
}
