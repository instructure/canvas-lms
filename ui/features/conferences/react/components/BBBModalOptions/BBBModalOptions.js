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
import {IconButton} from '@instructure/ui-buttons'
import {IconInfoLine} from '@instructure/ui-icons'
import {TextInput} from '@instructure/ui-text-input'
import {NumberInput} from '@instructure/ui-number-input'
import {Flex} from '@instructure/ui-flex'
import {TextArea} from '@instructure/ui-text-area'
import {Tabs} from '@instructure/ui-tabs'
import {Tooltip} from '@instructure/ui-tooltip'
import {DateTimeInput} from '@instructure/ui-date-time-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {SETTINGS_TAB, ATTENDEES_TAB} from '../../../util/constants'
import {View} from '@instructure/ui-view'
import DateHelper from '@canvas/datetime/dateHelper'

const I18n = useI18nScope('video_conference')

const BBBModalOptions = ({addToCalendar, setAddToCalendar, ...props}) => {
  const [noTimeLimit, setNoTimeLimit] = useState(props.options.includes('no_time_limit')) // match options.no_time_limit default

  const contextIsGroup = ENV.context_asset_string?.split('_')[0] === 'group'
  const inviteAllMembersText = contextIsGroup
    ? I18n.t('Invite all group members')
    : I18n.t('Invite all course members')

  return (
    <Tabs
      onRequestTabChange={(e, {id}) => {
        props.setTab(id)
      }}
    >
      <Tabs.Panel
        id={SETTINGS_TAB}
        renderTitle={I18n.t('Settings')}
        isSelected={props.tab === SETTINGS_TAB}
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
              isRequired={true}
              messages={props.nameValidationMessages}
            />
          </Flex.Item>
          <Flex.Item padding="small">
            <span data-testid="duration-input">
              <NumberInput
                renderLabel={I18n.t('Duration in Minutes')}
                display="inline-block"
                value={noTimeLimit ? '' : props.duration}
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
                interaction={noTimeLimit || props.hasBegun ? 'disabled' : 'enabled'}
                isRequired={!noTimeLimit}
                messages={props.durationValidationMessages}
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
                disabled={!ENV.bbb_recording_enabled}
              />
              <Checkbox
                label={I18n.t('No time limit (for long-running conferences)')}
                value="no_time_limit"
                onChange={event => {
                  setNoTimeLimit(event.target.checked)
                }}
                disabled={props.hasBegun}
              />
              <Checkbox
                label={I18n.t('Enable waiting room')}
                value="enable_waiting_room"
                disabled={props.hasBegun}
              />
              {!contextIsGroup && ENV.can_manage_calendar && (
                <Checkbox
                  label={I18n.t('Add to Calendar')}
                  value="add_to_calendar"
                  onChange={event => {
                    const confirmMessage = I18n.t(
                      'Checking Add to Calendar will invite all course members.'
                    )
                    if (event.target.checked) {
                      // eslint-disable-next-line no-alert
                      if (window.confirm(confirmMessage)) {
                        setAddToCalendar(event.target.checked)
                        // due to calendar api, it sends invite to full course, thus invite_all must be checked
                        if (event.target.checked) {
                          props.onSetInvitationOptions(['invite_all'])
                        }
                      } else {
                        // This does not stop the button click, however it will
                        // prevent all the state changes it would have set off.
                        // We cannot stop a button click. Thus we must re-click.
                        // Ensures this code runs AFTER the browser handles click however it wants.
                        setTimeout(() => {
                          document
                            .querySelector('input[type="checkbox"][value="add_to_calendar"]')
                            .click()
                          setAddToCalendar(false)
                        }, 0)
                      }
                    } else {
                      // You are unchecking.
                      setAddToCalendar(false)
                    }
                  }}
                  disabled={props.hasBegun}
                />
              )}
            </CheckboxGroup>
          </Flex.Item>
          {props.startDate && props.hasBegun && (
            <Flex.Item padding="small" data-testid="plain-text-dates">
              <div>
                <span>{`${I18n.t('Start at: ')} ${DateHelper.formatDatetimeForDisplay(
                  props.startDate
                )}`}</span>
              </div>
              {props.endDate && (
                <div>
                  <span>{`${I18n.t('End at: ')} ${DateHelper.formatDatetimeForDisplay(
                    props.endDate
                  )}`}</span>
                </div>
              )}
            </Flex.Item>
          )}
          {props.showCalendar && !props.hasBegun && (
            <Flex.Item>
              <Flex wrap="wrap">
                <Flex.Item padding="small" align="start">
                  <DateTimeInput
                    data-testId="start-date-input"
                    onChange={(e, newValue) => {
                      props.onStartDateChange(newValue)
                    }}
                    layout="columns"
                    dateRenderLabel={I18n.t('Start Date')}
                    timeRenderLabel={I18n.t('Start Time')}
                    value={props.startDate}
                    invalidDateTimeMessage={I18n.t('Invalid date and time')}
                    nextMonthLabel={I18n.t('Next Month')}
                    prevMonthLabel={I18n.t('Previous Month')}
                    description={
                      <ScreenReaderContent>
                        {I18n.t('Start Date for Conference')}
                      </ScreenReaderContent>
                    }
                    messages={props.calendarValidationMessages[0]}
                  />
                </Flex.Item>
                <Flex.Item padding="small none small small" align="start">
                  <DateTimeInput
                    data-testId="end-date-input"
                    onChange={(e, newValue) => {
                      props.onEndDateChange(newValue)
                    }}
                    layout="columns"
                    dateRenderLabel={I18n.t('End Date')}
                    timeRenderLabel={I18n.t('End Time')}
                    value={props.endDate}
                    invalidDateTimeMessage={I18n.t('Invalid date and time')}
                    nextMonthLabel={I18n.t('Next Month')}
                    prevMonthLabel={I18n.t('Previous Month')}
                    description={
                      <ScreenReaderContent>{I18n.t('End Date for Conference')}</ScreenReaderContent>
                    }
                    messages={props.calendarValidationMessages[1]}
                  />
                </Flex.Item>
              </Flex>
            </Flex.Item>
          )}
          <Flex.Item padding="small">
            <TextArea
              label={I18n.t('Description')}
              placeholder={I18n.t('Conference Description')}
              value={props.description}
              onChange={e => {
                props.onSetDescription(e.target.value)
              }}
              messages={props.descriptionValidationMessages}
            />
          </Flex.Item>
        </Flex>
      </Tabs.Panel>
      <Tabs.Panel
        id={ATTENDEES_TAB}
        renderTitle={I18n.t('Attendees')}
        isSelected={props.tab === ATTENDEES_TAB}
      >
        <Flex margin="none none large" direction="column">
          <Flex.Item padding="small">
            <CheckboxGroup
              name="invitation_options"
              onChange={value => {
                // make sure to uncheck remove_observers if invite_all is unchecked
                if (!value.includes('invite_all') && value.indexOf('remove_observers') > -1) {
                  value.splice(value.indexOf('remove_observers'), 1)
                }
                props.onSetInvitationOptions([...value])
              }}
              defaultValue={props.invitationOptions}
              description={
                <View>
                  {I18n.t('Invitation Options')}
                  {addToCalendar && (
                    <Tooltip
                      renderTip={I18n.t('All course members must be invited to calendar events.')}
                      placement="end"
                      on={['click', 'hover', 'focus']}
                    >
                      <IconButton
                        renderIcon={IconInfoLine}
                        withBackground={false}
                        withBorder={false}
                        screenReaderLabel="Toggle Tooltip"
                        data-testid="inviteAll-tooltip"
                      />
                    </Tooltip>
                  )}
                </View>
              }
            >
              <Checkbox label={inviteAllMembersText} value="invite_all" disabled={addToCalendar} />
              {!contextIsGroup && (
                <Checkbox
                  label={I18n.t('Remove all course observer members')}
                  value="remove_observers"
                  disabled={addToCalendar || !props.invitationOptions.includes('invite_all')}
                />
              )}
            </CheckboxGroup>
          </Flex.Item>
          {props.showAddressBook && (
            <Flex.Item padding="small">
              <ConferenceAddressBook
                data-testId="conference-address-book"
                selectedItems={props.selectedAttendees}
                menuItemList={props.availableAttendeesList}
                onChange={menuItemList => {
                  props.onAttendeesChange(menuItemList)
                }}
                isEditing={props.isEditing}
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
              <Checkbox
                label={I18n.t('Share webcam')}
                value="share_webcam"
                disabled={props.hasBegun}
              />
              <Checkbox
                label={I18n.t('See other viewers webcams')}
                value="share_other_webcams"
                disabled={props.hasBegun}
              />
              <Checkbox
                label={I18n.t('Share microphone')}
                value="share_microphone"
                disabled={props.hasBegun}
              />
              <Checkbox
                label={I18n.t('Send public chat messages')}
                value="send_public_chat"
                disabled={props.hasBegun}
              />
              <Checkbox
                label={I18n.t('Send private chat messages')}
                value="send_private_chat"
                disabled={props.hasBegun}
              />
            </CheckboxGroup>
          </Flex.Item>
        </Flex>
      </Tabs.Panel>
    </Tabs>
  )
}

BBBModalOptions.defaultProps = {
  calendarValidationMessages: [],
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
  selectedAttendees: PropTypes.arrayOf(PropTypes.object),
  showCalendar: PropTypes.bool,
  setAddToCalendar: PropTypes.func,
  addToCalendar: PropTypes.bool,
  onEndDateChange: PropTypes.func,
  onStartDateChange: PropTypes.func,
  startDate: PropTypes.string,
  endDate: PropTypes.string,
  calendarValidationMessages: PropTypes.array,
  tab: PropTypes.string,
  setTab: PropTypes.func,
  nameValidationMessages: PropTypes.array,
  descriptionValidationMessages: PropTypes.array,
  hasBegun: PropTypes.bool,
  durationValidationMessages: PropTypes.array,
  isEditing: PropTypes.bool,
}

export default BBBModalOptions
