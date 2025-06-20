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

import {useScope as createI18nScope} from '@canvas/i18n'
import React, {useEffect, useState} from 'react'
import {Modal} from '@instructure/ui-modal'
import {Heading} from '@instructure/ui-heading'
import {Button, CloseButton} from '@instructure/ui-buttons'
import VideoConferenceTypeSelect from '../VideoConferenceTypeSelect/VideoConferenceTypeSelect'
import BBBModalOptions from '../BBBModalOptions/BBBModalOptions'
import BaseModalOptions from '../BaseModalOptions/BaseModalOptions'
import {SETTINGS_TAB, ATTENDEES_TAB} from '../../../util/constants'
import {Spinner} from '@instructure/ui-spinner'
import {IconWarningSolid} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('video_conference')

type Attendee = {
  displayName: string
  id: string
  assetCode: string
}

type VideoConferenceModalProps = {
  open: boolean
  onDismiss: () => void
  onSubmit: (e: React.FormEvent, data: any) => Promise<boolean>
  isEditing?: boolean
  hasBegun?: boolean
  name?: string
  duration?: number
  options?: string[]
  description?: string
  invitationOptions?: string[]
  attendeesOptions?: string[]
  type?: string
  availableAttendeesList?: Attendee[]
  selectedAttendees?: Attendee[]
  startCalendarDate?: string
  endCalendarDate?: string
}

export const VideoConferenceModal = ({
  availableAttendeesList,
  isEditing = false,
  open,
  onDismiss,
  onSubmit,
  ...props
}: VideoConferenceModalProps) => {
  const OPTIONS_DEFAULT: string[] = []

  if ((ENV as any).bbb_recording_enabled) {
    OPTIONS_DEFAULT.push('recording_enabled')
  }
  const INVITATION_OPTIONS_DEFAULT = ['invite_all']
  const ATTENDEES_OPTIONS_DEFAULT = [
    'share_webcam',
    'share_other_webcams',
    'share_microphone',
    'send_public_chat',
    'send_private_chat',
  ]

  const [tab, setTab] = useState(SETTINGS_TAB)
  const defaultName = (ENV as any).context_name
    ? `${(ENV as any).context_name} Conference`
    : 'Conference'
  const [name, setName] = useState(isEditing ? props.name : defaultName)
  const [conferenceType, setConferenceType] = useState(
    isEditing ? props.type : (window.ENV as any).conference_type_details[0].type,
  )
  const [duration, setDuration] = useState(isEditing ? props.duration : 60)
  const [options, setOptions] = useState(isEditing ? props.options : OPTIONS_DEFAULT)

  const [description, setDescription] = useState(isEditing ? props.description : '')
  const [invitationOptions, setInvitationOptions] = useState(
    isEditing ? props.invitationOptions : INVITATION_OPTIONS_DEFAULT,
  )
  const [attendeesOptions, setAttendeesOptions] = useState(
    isEditing ? props.attendeesOptions : ATTENDEES_OPTIONS_DEFAULT,
  )
  const [showAddressBook, setShowAddressBook] = useState(false)
  const [selectedAttendees, setSelectedAttendees] = useState<Attendee[]>(
    props.selectedAttendees ? props.selectedAttendees : [],
  )
  const [startCalendarDate, setStartCalendarDate] = useState(
    props.startCalendarDate ? props.startCalendarDate : new Date().toISOString(),
  )
  const [endCalendarDate, setEndCalendarDate] = useState(
    props.endCalendarDate ? props.endCalendarDate : new Date().toISOString(),
  )

  const [showCalendarOptions, setShowCalendarOptions] = useState(false)
  const [isLoading, setIsLoading] = useState(false)

  const [nameValidationMessages, setNameValidationMessages] = useState<
    Array<{text: any; type: string}>
  >([])
  const [durationValidationMessages, setDurationValidationMessages] = useState<
    Array<{text: any; type: string}>
  >([])
  const [descriptionValidationMessages, setDescriptionValidationMessages] = useState<
    Array<{text: any; type: string}>
  >([])
  const [calendarValidationMessages, setCalendarValidationMessages] = useState<
    Array<Array<{text: any; type: string}>>
  >([])
  const [addToCalendar, setAddToCalendar] = useState((options || []).includes('add_to_calendar'))

  const onStartDateChange = (newValue: string) => {
    setStartCalendarDate(newValue)
  }

  const onEndDateChange = (newValue: string) => {
    setEndCalendarDate(newValue)
  }

  const retrieveErrorMessage = (error: string) => (
    <span>
      <View as="span" display="inline-block" margin="0 xxx-small xx-small 0">
        <IconWarningSolid />
      </View>
      &nbsp;
      {error}
    </span>
  )

  const setAndValidateName = (nameToBeValidated: string) => {
    if (nameToBeValidated.length > 255) {
      setNameValidationMessages([
        {text: retrieveErrorMessage(I18n.t('Name must not exceed 255 characters')), type: 'error'},
      ])
    } else if (nameToBeValidated.length === 0) {
      setName('')
      setNameValidationMessages([
        {text: retrieveErrorMessage(I18n.t('Please fill this field')), type: 'error'},
      ])
    } else {
      setNameValidationMessages([])
      setName(nameToBeValidated)
    }
  }

  const setAndValidateDuration = (durationToBeValidated: number | string) => {
    const numValue =
      typeof durationToBeValidated === 'string'
        ? parseInt(durationToBeValidated, 10)
        : durationToBeValidated
    if (durationToBeValidated.toString().length > 8) {
      setDurationValidationMessages([
        {
          text: retrieveErrorMessage(
            I18n.t('Duration must be less than or equal to 99,999,999 minutes'),
          ),
          type: 'error',
        },
      ])
      if (durationValidationMessages.length === 0) {
        setDuration(numValue)
      }
    } else if (Number(durationToBeValidated) === 0) {
      setDurationValidationMessages([
        {
          text: retrieveErrorMessage(I18n.t('Duration must be greater than 0 minute')),
          type: 'error',
        },
      ])
      setDuration(numValue)
    } else {
      setDurationValidationMessages([])
      setDuration(numValue)
    }
  }

  const setAndValidateDescription = (descriptionToBeValidated: string) => {
    if (descriptionToBeValidated.length > 2500) {
      setDescriptionValidationMessages([
        {
          text: retrieveErrorMessage(I18n.t('Description must not exceed 2500 characters')),
          type: 'error',
        },
      ])
    } else {
      setDescriptionValidationMessages([])
      setDescription(descriptionToBeValidated)
    }
  }

  // Detect initial state for address book display
  useEffect(() => {
    const inviteAll = (invitationOptions || []).includes('invite_all')
    setShowAddressBook(!inviteAll)
  }, [invitationOptions])

  // Detect initial state for calender picker display
  useEffect(() => {
    setShowCalendarOptions(addToCalendar)
  }, [addToCalendar])

  const normalizeDate = (calendarString: string | null) => {
    if (!calendarString) {
      return null
    }
    const date = new Date(calendarString)
    if (!Number.isNaN(date) && date instanceof Date) {
      return date.toISOString()
    } else {
      return calendarString
    }
  }

  // Validate Calendar EndAt > StartAt
  useEffect(() => {
    const endDate = normalizeDate(endCalendarDate)
    const startDate = normalizeDate(startCalendarDate)

    if (
      (addToCalendar && endDate && startDate && !(endDate > startDate)) ||
      (addToCalendar && (!endDate || !startDate))
    ) {
      setCalendarValidationMessages([
        [{text: I18n.t('Start Date/Time must be before the End Date/Time'), type: 'error'}],
        [{text: I18n.t('End Date/Time must be later than Start Date/Time'), type: 'error'}],
      ])
    } else {
      setCalendarValidationMessages([])
    }
  }, [addToCalendar, startCalendarDate, endCalendarDate])

  const renderCloseButton = () => {
    return (
      <CloseButton
        placement="end"
        offset="medium"
        onClick={onDismiss}
        screenReaderLabel={I18n.t('Close')}
      />
    )
  }

  const header = isEditing ? I18n.t('Edit Video Conference') : I18n.t('New Video Conference')

  const renderModalOptions = () => {
    if (conferenceType === 'BigBlueButton') {
      return (
        <BBBModalOptions
          name={name}
          onSetName={setAndValidateName}
          duration={duration}
          onSetDuration={setAndValidateDuration}
          durationValidationMessages={durationValidationMessages}
          options={options}
          onSetOptions={setOptions}
          description={description}
          onSetDescription={setAndValidateDescription}
          invitationOptions={invitationOptions}
          onSetInvitationOptions={setInvitationOptions}
          attendeesOptions={attendeesOptions}
          onSetAttendeesOptions={setAttendeesOptions}
          showAddressBook={showAddressBook}
          onAttendeesChange={setSelectedAttendees as any}
          availableAttendeesList={availableAttendeesList}
          selectedAttendees={selectedAttendees as any}
          showCalendar={showCalendarOptions}
          setAddToCalendar={setAddToCalendar}
          addToCalendar={addToCalendar}
          startDate={startCalendarDate}
          endDate={endCalendarDate}
          onStartDateChange={onStartDateChange}
          onEndDateChange={onEndDateChange}
          calendarValidationMessages={calendarValidationMessages}
          tab={tab}
          setTab={setTab}
          nameValidationMessages={nameValidationMessages}
          descriptionValidationMessages={descriptionValidationMessages}
          hasBegun={props.hasBegun}
          isEditing={isEditing}
        />
      )
    }

    return (
      <BaseModalOptions
        name={name}
        onSetName={setAndValidateName}
        duration={duration}
        onSetDuration={setAndValidateDuration}
        durationValidationMessages={durationValidationMessages}
        options={options}
        onSetOptions={setOptions}
        description={description}
        onSetDescription={setAndValidateDescription}
        invitationOptions={invitationOptions}
        onSetInvitationOptions={setInvitationOptions}
        showAddressBook={showAddressBook}
        onAttendeesChange={setSelectedAttendees as any}
        availableAttendeesList={availableAttendeesList}
        selectedAttendees={selectedAttendees as any}
        nameValidationMessages={nameValidationMessages}
        descriptionValidationMessages={descriptionValidationMessages}
        hasBegun={props.hasBegun}
        isEditing={isEditing}
      />
    )
  }

  return (
    <Modal
      as="form"
      open={open}
      onDismiss={onDismiss}
      onSubmit={async e => {
        e.preventDefault()
        if (tab === ATTENDEES_TAB) {
          setTab(SETTINGS_TAB)
          setTimeout(() => {
            ;(document.querySelector('button[type=submit]') as HTMLButtonElement)?.click()
          }, 200)
          return
        }

        setIsLoading(true)

        const submitted = await onSubmit(e, {
          name,
          conferenceType,
          duration,
          options,
          description,
          invitationOptions,
          attendeesOptions,
          selectedAttendees,
          startCalendarDate,
          endCalendarDate,
        })

        if (!submitted) {
          setIsLoading(false)
        }
      }}
      size="large"
      label={header}
      shouldCloseOnDocumentClick={false}
    >
      <Modal.Header>
        {renderCloseButton()}
        <Heading>{header}</Heading>
      </Modal.Header>
      <Modal.Body padding="none" overflow="fit">
        {/* @ts-expect-error VideoConferenceTypeSelect is JSX component */}
        <VideoConferenceTypeSelect
          conferenceTypes={(window.ENV as any).conference_type_details}
          onSetConferenceType={(type: string) => setConferenceType(type)}
          isEditing={isEditing}
        />
        {renderModalOptions()}
      </Modal.Body>
      <Modal.Footer>
        <Button
          disabled={isLoading}
          onClick={onDismiss}
          margin="0 x-small 0 0"
          data-testid="cancel-button"
        >
          {I18n.t('Cancel')}
        </Button>
        <Button
          color="primary"
          type="submit"
          data-testid="submit-button"
          disabled={
            isLoading ||
            nameValidationMessages.length > 0 ||
            calendarValidationMessages.length > 0 ||
            descriptionValidationMessages.length > 0 ||
            durationValidationMessages.length > 0
          }
        >
          {isLoading ? (
            <div style={{display: 'inline-block', margin: '-0.5rem 0.9rem'}}>
              <Spinner
                renderTitle={isEditing ? I18n.t('Saving') : I18n.t('Creating')}
                size="x-small"
              />
            </div>
          ) : isEditing ? (
            I18n.t('Save')
          ) : (
            I18n.t('Create')
          )}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export default VideoConferenceModal
