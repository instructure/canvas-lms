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

const I18n = useI18nScope('video_conference')

export const VideoConferenceModal = ({
  availableAttendeesList,
  isEditing,
  open,
  onDismiss,
  onSubmit,
  ...props
}) => {
  const OPTIONS_DEFAULT = ['recording_enabled', 'no_time_limit', 'enable_waiting_room']
  const INVITATION_OPTIONS_DEFAULT = ['invite_all']
  const ATTENDEES_OPTIONS_DEFAULT = [
    'share_webcam',
    'share_other_webcams',
    'share_microphone',
    'send_public_chat',
    'send_private_chat'
  ]

  const [name, setName] = useState(isEditing ? props.name : '')
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

  // Detect initial state for address book display
  useEffect(() => {
    const inviteAll = invitationOptions.includes('invite_all')
    inviteAll ? setShowAddressBook(false) : setShowAddressBook(true)
  }, [invitationOptions])

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
          onSetName={setName}
          duration={duration}
          onSetDuration={setDuration}
          options={options}
          onSetOptions={setOptions}
          description={description}
          onSetDescription={setDescription}
          invitationOptions={invitationOptions}
          onSetInvitationOptions={setInvitationOptions}
          attendeesOptions={attendeesOptions}
          onSetAttendeesOptions={setAttendeesOptions}
          showAddressBook={showAddressBook}
          onAttendeesChange={setSelectedAttendees}
          availableAttendeesList={availableAttendeesList}
          selectedAttendees={selectedAttendees}
        />
      )
    }

    return (
      <BaseModalOptions
        name={name}
        onSetName={setName}
        duration={duration}
        onSetDuration={setDuration}
        options={options}
        onSetOptions={setOptions}
        description={description}
        onSetDescription={setDescription}
        invitationOptions={invitationOptions}
        onSetInvitationOptions={setInvitationOptions}
        showAddressBook={showAddressBook}
        onAttendeesChange={setSelectedAttendees}
        availableAttendeesList={availableAttendeesList}
        selectedAttendees={selectedAttendees}
      />
    )
  }

  return (
    <Modal
      as="form"
      open={open}
      onDismiss={onDismiss}
      onSubmit={e => {
        e.preventDefault()
        onSubmit(e, {
          name,
          conferenceType,
          duration,
          options,
          description,
          invitationOptions,
          attendeesOptions,
          selectedAttendees
        })
      }}
      size="auto"
      label={header}
      shouldCloseOnDocumentClick
    >
      <Modal.Header>
        {renderCloseButton()}
        <Heading>{header}</Heading>
      </Modal.Header>
      <Modal.Body padding="none" overflow="fit">
        <VideoConferenceTypeSelect
          conferenceTypes={window.ENV.conference_type_details}
          onSetConferenceType={type => setConferenceType(type)}
        />
        {renderModalOptions()}
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={onDismiss} margin="0 x-small 0 0" data-testid="cancel-button">
          {I18n.t('Cancel')}
        </Button>
        <Button color="primary" type="submit" data-testid="submit-button">
          {isEditing ? I18n.t('Save') : I18n.t('Create')}
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
  name: PropTypes.string,
  duration: PropTypes.number,
  options: PropTypes.arrayOf(PropTypes.string),
  description: PropTypes.string,
  invitationOptions: PropTypes.arrayOf(PropTypes.string),
  attendeesOptions: PropTypes.arrayOf(PropTypes.string),
  type: PropTypes.string,
  availableAttendeesList: PropTypes.arrayOf(PropTypes.object),
  selectedAttendees: PropTypes.arrayOf(PropTypes.string)
}

VideoConferenceModal.defaultProps = {
  isEditing: false
}

export default VideoConferenceModal
