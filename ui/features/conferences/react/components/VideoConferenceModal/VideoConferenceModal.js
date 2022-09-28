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
import React, {useEffect, useState} from 'react'
import PropTypes from 'prop-types'
import {Modal} from '@instructure/ui-modal'
import {Heading} from '@instructure/ui-heading'
import {Button, CloseButton} from '@instructure/ui-buttons'
import VideoConferenceTypeSelect from '../VideoConferenceTypeSelect/VideoConferenceTypeSelect'
import BBBModalOptions from '../BBBModalOptions/BBBModalOptions'
import BaseModalOptions from '../BaseModalOptions/BaseModalOptions'
import {SETTINGS_TAB, ATTENDEES_TAB} from '../../../util/constants'
import {Spinner} from '@instructure/ui-spinner'

const I18n = useI18nScope('video_conference')

export const VideoConferenceModal = ({
  availableAttendeesList,
  isEditing,
  open,
  onDismiss,
  onSubmit,
  ...props
}) => {
  const OPTIONS_DEFAULT = []

  if (ENV.bbb_recording_enabled) {
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
  const defaultName = ENV.context_name ? `${ENV.context_name} Conference` : 'Conference'
  const [name, setName] = useState(isEditing ? props.name : defaultName)
  const [conferenceType, setConferenceType] = useState(
    isEditing ? props.type : window.ENV.conference_type_details[0].type
  )
  const [duration, setDuration] = useState(isEditing ? props.duration : 60)
  const [options, setOptions] = useState(isEditing ? props.options : OPTIONS_DEFAULT)

  const [description, setDescription] = useState(isEditing ? props.description : '')
  const [invitationOptions, setInvitationOptions] = useState(
    isEditing ? props.invitationOptions : INVITATION_OPTIONS_DEFAULT
  )
  const [attendeesOptions, setAttendeesOptions] = useState(
    isEditing ? props.attendeesOptions : ATTENDEES_OPTIONS_DEFAULT
  )
  const [showAddressBook, setShowAddressBook] = useState(false)
  const [selectedAttendees, setSelectedAttendees] = useState(
    props.selectedAttendees ? props.selectedAttendees : []
  )
  const [startCalendarDate, setStartCalendarDate] = useState(
    props.startCalendarDate ? props.startCalendarDate : new Date().toISOString()
  )
  const [endCalendarDate, setEndCalendarDate] = useState(
    props.endCalendarDate ? props.endCalendarDate : new Date().toISOString()
  )

  const [showCalendarOptions, setShowCalendarOptions] = useState(false)
  const [isLoading, setIsLoading] = useState(false)

  const [nameValidationMessages, setNameValidationMessages] = useState([])
  const [durationValidationMessages, setDurationValidationMessages] = useState([])
  const [descriptionValidationMessages, setDescriptionValidationMessages] = useState([])
  const [calendarValidationMessages, setCalendarValidationMessages] = useState([])
  const [addToCalendar, setAddToCalendar] = useState(options.includes('add_to_calendar'))

  const onStartDateChange = newValue => {
    setStartCalendarDate(newValue)
  }

  const onEndDateChange = newValue => {
    setEndCalendarDate(newValue)
  }

  const setAndValidateName = nameToBeValidated => {
    if (nameToBeValidated.length > 255) {
      setNameValidationMessages([
        {text: I18n.t('Name must be less than 255 characters'), type: 'error'},
      ])
    } else {
      setNameValidationMessages([])
      setName(nameToBeValidated)
    }
  }

  const setAndValidateDuration = durationToBeValidated => {
    if (durationToBeValidated.toString().length > 8) {
      if (durationValidationMessages.length === 0) {
        setDuration(durationToBeValidated)
      }
      setDurationValidationMessages([
        {text: I18n.t('Duration must be less than 99,999,999 minutes'), type: 'error'},
      ])
    } else {
      setDurationValidationMessages([])
      setDuration(durationToBeValidated)
    }
  }

  const setAndValidateDescription = descriptionToBeValidated => {
    if (descriptionToBeValidated.length > 2500) {
      setDescriptionValidationMessages([
        {text: I18n.t('Description must be less than 2500 characters'), type: 'error'},
      ])
    } else {
      setDescriptionValidationMessages([])
      setDescription(descriptionToBeValidated)
    }
  }

  // Detect initial state for address book display
  useEffect(() => {
    const inviteAll = invitationOptions.includes('invite_all')
    inviteAll ? setShowAddressBook(false) : setShowAddressBook(true)
  }, [invitationOptions])

  // Detect initial state for calender picker display
  useEffect(() => {
    addToCalendar ? setShowCalendarOptions(true) : setShowCalendarOptions(false)
  }, [addToCalendar])

  const normalizeDate = calendarString => {
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

    if ((addToCalendar && !(endDate > startDate)) || !endDate || !startDate) {
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
          onAttendeesChange={setSelectedAttendees}
          availableAttendeesList={availableAttendeesList}
          selectedAttendees={selectedAttendees}
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
        onAttendeesChange={setSelectedAttendees}
        availableAttendeesList={availableAttendeesList}
        selectedAttendees={selectedAttendees}
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
            document.querySelector('button[type=submit]').click()
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
        <VideoConferenceTypeSelect
          conferenceTypes={window.ENV.conference_type_details}
          onSetConferenceType={type => setConferenceType(type)}
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

VideoConferenceModal.propTypes = {
  open: PropTypes.bool,
  onDismiss: PropTypes.func,
  onSubmit: PropTypes.func,
  isEditing: PropTypes.bool,
  hasBegun: PropTypes.bool,
  name: PropTypes.string,
  duration: PropTypes.number,
  options: PropTypes.arrayOf(PropTypes.string),
  description: PropTypes.string,
  invitationOptions: PropTypes.arrayOf(PropTypes.string),
  attendeesOptions: PropTypes.arrayOf(PropTypes.string),
  type: PropTypes.string,
  availableAttendeesList: PropTypes.arrayOf(PropTypes.object),
  selectedAttendees: PropTypes.arrayOf(PropTypes.object),
  startCalendarDate: PropTypes.string,
  endCalendarDate: PropTypes.string,
}

VideoConferenceModal.defaultProps = {
  isEditing: false,
}

export default VideoConferenceModal
