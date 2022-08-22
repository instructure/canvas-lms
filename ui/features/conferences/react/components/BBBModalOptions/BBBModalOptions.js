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
import PropTypes from 'prop-types'
import {Checkbox, CheckboxGroup} from '@instructure/ui-checkbox'
import {ConferenceAddressBook} from '../ConferenceAddressBook/ConferenceAddressBook'
import {TextInput} from '@instructure/ui-text-input'
import {NumberInput} from '@instructure/ui-number-input'
import {Flex} from '@instructure/ui-flex'
import {TextArea} from '@instructure/ui-text-area'
import {Tabs} from '@instructure/ui-tabs'

const I18n = useI18nScope('video_conference')

const BBBModalOptions = props => {
  const SETTINGS_TAB = 'settings'
  const ATTENDEES_TAB = 'attendees'

  const [tab, setTab] = useState(SETTINGS_TAB)

  return (
    <Tabs
      onRequestTabChange={(e, {id}) => {
        setTab(id)
      }}
    >
      <Tabs.Panel
        id={SETTINGS_TAB}
        renderTitle={I18n.t('Settings')}
        isSelected={tab === SETTINGS_TAB}
      >
        <Flex margin="none none large" direction="column">
          <Flex.Item padding="small">
            <TextInput
              renderLabel={I18n.t('Name')}
              placeholder={I18n.t('Conference Name')}
              value={props.name}
              onChange={(e, value) => {
                props.onSetName(value)
              }}
              isRequired
            />
          </Flex.Item>
          <Flex.Item padding="small">
            <span data-testid="duration-input">
              <NumberInput
                renderLabel={I18n.t('Duration in Minutes')}
                display="inline-block"
                value={props.duration}
                onChange={(e, value) => {
                  if (!Number.isInteger(Number(value))) return

                  props.onSetDuration(Number(value))
                }}
                onIncrement={() => {
                  if (!Number.isInteger(props.duration)) return

                  props.onSetDuration(props.duration + 1)
                }}
                onDecrement={() => {
                  if (!Number.isInteger(props.duration)) return
                  if (props.duration === 0) return

                  props.onSetDuration(props.duration - 1)
                }}
                isRequired
              />
            </span>
          </Flex.Item>
          <Flex.Item padding="small">
            <CheckboxGroup
              name="options"
              onChange={value => {
                props.onSetOptions(value)
              }}
              defaultValue={props.options}
              description={I18n.t('Options')}
            >
              <Checkbox
                label={I18n.t('Enable recording for this conference')}
                value="recording_enabled"
              />
              <Checkbox
                label={I18n.t('No time limit (for long-running conferences)')}
                value="no_time_limit"
              />
              <Checkbox label={I18n.t('Enable waiting room')} value="enable_waiting_room" />
              <Checkbox label={I18n.t('Add to Calendar')} value="add_to_calendar" />
            </CheckboxGroup>
          </Flex.Item>
          <Flex.Item padding="small">
            <TextArea
              label={I18n.t('Description')}
              placeholder={I18n.t('Conference Description')}
              value={props.description}
              onChange={e => {
                props.onSetDescription(e.target.value)
              }}
            />
          </Flex.Item>
        </Flex>
      </Tabs.Panel>
      <Tabs.Panel
        id={ATTENDEES_TAB}
        renderTitle={I18n.t('Attendees')}
        isSelected={tab === ATTENDEES_TAB}
      >
        <Flex margin="none none large" direction="column">
          <Flex.Item padding="small">
            <CheckboxGroup
              name="invitation_options"
              onChange={value => {
                props.onSetInvitationOptions([...value])
              }}
              defaultValue={props.invitationOptions}
              description={I18n.t('Invitation Options')}
            >
              <Checkbox label={I18n.t('Invite all course members')} value="invite_all" />
              <Checkbox
                label={I18n.t('Remove all course observer members')}
                value="remove_observers"
              />
            </CheckboxGroup>
          </Flex.Item>
          {props.showAddressBook && (
            <Flex.Item padding="small">
              <ConferenceAddressBook
                data-testId="conference-address-book"
                selectedIds={props.selectedAttendees}
                userList={props.availableAttendeesList}
                onChange={userList => {
                  props.onAttendeesChange(userList.map(u => u.id))
                }}
              />
            </Flex.Item>
          )}
          <Flex.Item padding="small">
            <CheckboxGroup
              name="attendees_options"
              onChange={value => {
                props.onSetAttendeesOptions(value)
              }}
              defaultValue={props.attendeesOptions}
              description={I18n.t('Allow Attendees To...')}
            >
              <Checkbox label={I18n.t('Share webcam')} value="share_webcam" />
              <Checkbox label={I18n.t('See other viewers webcams')} value="share_other_webcams" />
              <Checkbox label={I18n.t('Share microphone')} value="share_microphone" />
              <Checkbox label={I18n.t('Send public chat messages')} value="send_public_chat" />
              <Checkbox label={I18n.t('Send private chat messages')} value="send_private_chat" />
            </CheckboxGroup>
          </Flex.Item>
        </Flex>
      </Tabs.Panel>
    </Tabs>
  )
}

BBBModalOptions.propTypes = {
  name: PropTypes.string,
  onSetName: PropTypes.func,
  duration: PropTypes.number,
  onSetDuration: PropTypes.func,
  options: PropTypes.array,
  onSetOptions: PropTypes.func,
  description: PropTypes.string,
  onSetDescription: PropTypes.func,
  invitationOptions: PropTypes.array,
  onSetInvitationOptions: PropTypes.func,
  attendeesOptions: PropTypes.array,
  onSetAttendeesOptions: PropTypes.func,
  showAddressBook: PropTypes.bool,
  onAttendeesChange: PropTypes.func,
  availableAttendeesList: PropTypes.arrayOf(PropTypes.object),
  selectedAttendees: PropTypes.arrayOf(PropTypes.string)
}

export default BBBModalOptions
