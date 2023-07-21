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

import React from 'react'

import BBBModalOptions from './BBBModalOptions'

export default {
  title: 'Examples/Conferences/BBBModalOptions',
  component: BBBModalOptions,
  argTypes: {},
}

const defaultProps = {
  name: 'Conference 1',
  setName: () => {},
  duration: 46,
  setDuration: () => {},
  options: ['no_time_limit'],
  setOptions: () => {},
  description: 'First conference of all time',
  setDescription: () => {},
  invitationOptions: ['invite_all'],
  setInvitationOptions: () => {},
  attendeesOptions: [
    'share_webcam',
    'share_other_webcams',
    'share_microphone',
    'send_public_chat',
    'send_private_chat',
  ],
  setAttendeesOptions: () => {},
}

const Template = props => (
  <BBBModalOptions
    name={props.name}
    onSetName={props.setName}
    duration={props.duration}
    onSetDuration={props.setDuration}
    options={props.options}
    onSetOptions={props.setOptions}
    description={props.description}
    onSetDescription={props.setDescription}
    invitationOptions={props.invitationOptions}
    onSetInvitationOptions={props.setInvitationOptions}
    attendeesOptions={props.attendeesOptions}
    onSetAttendeesOptions={props.setAttendeesOptions}
    showCalendar={props.showCalendar}
  />
)

window.ENV.bbb_recording_enabled = true

export const Default = Template.bind({})
Default.args = {...defaultProps}

export const WithCalendar = Template.bind({})
WithCalendar.args = {...defaultProps, showCalendar: true}
