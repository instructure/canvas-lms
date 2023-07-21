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

const I18n = useI18nScope('video_conference')

const BaseModalOptions = props => {
  const [noTimeLimit, setNoTimeLimit] = useState(props.options.includes('no_time_limit'))

  return (
    <>
      <Flex margin="none none large" direction="column">
        <Flex.Item padding="medium">
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
        <Flex.Item padding="medium">
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
        <Flex.Item padding="medium">
          <CheckboxGroup
            name="options"
            onChange={value => {
              props.onSetOptions(value)
            }}
            defaultValue={props.options}
            description={I18n.t('Options')}
          >
            <Checkbox
              label={I18n.t('No time limit (for long-running conferences)')}
              value="no_time_limit"
              onChange={event => {
                setNoTimeLimit(event.target.checked)
              }}
              disabled={props.hasBegun}
            />
          </CheckboxGroup>
        </Flex.Item>
        <Flex.Item padding="medium">
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
          <Flex.Item padding="medium">
            <ConferenceAddressBook
              data-testid="conference-address-book"
              selectedItems={props.selectedAttendees}
              menuItemList={props.availableAttendeesList}
              onChange={menuItemList => {
                props.onAttendeesChange(menuItemList)
              }}
              isEditing={props.isEditing}
            />
          </Flex.Item>
        )}
        <Flex.Item padding="medium">
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
    </>
  )
}

BaseModalOptions.propTypes = {
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
  showAddressBook: PropTypes.bool,
  onAttendeesChange: PropTypes.func,
  availableAttendeesList: PropTypes.arrayOf(PropTypes.object),
  selectedAttendees: PropTypes.arrayOf(PropTypes.string),
  nameValidationMessages: PropTypes.array,
  descriptionValidationMessages: PropTypes.array,
  hasBegun: PropTypes.bool,
  durationValidationMessages: PropTypes.array,
  isEditing: PropTypes.bool,
}

export default BaseModalOptions
