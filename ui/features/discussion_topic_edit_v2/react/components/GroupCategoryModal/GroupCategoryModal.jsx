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

import React, {useState, useRef} from 'react'
import PropTypes from 'prop-types'
import {Button, CloseButton, IconButton} from '@instructure/ui-buttons'
import {IconInfoLine} from '@instructure/ui-icons'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {Checkbox} from '@instructure/ui-checkbox'
import {TextInput} from '@instructure/ui-text-input'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {NumberInput} from '@instructure/ui-number-input'
import {Tooltip} from '@instructure/ui-tooltip'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {useScope as usei18NScope} from '@canvas/i18n'

const I18N = usei18NScope('discussion_create')

export default function GroupCategoryModal({show, setShow, onSubmit}) {
  const defaultFocusElementRef = useRef(null)

  // Form properties
  const [groupName, setGroupName] = useState('')
  const [groupStructure, setGroupStructure] = useState('')
  const [allowSelfSignup, setAllowSelfSignup] = useState(false)
  const [requireSameSection, setRequireSameSection] = useState(false)
  const [autoAssignGroupLeader, setAutoAssignGroupLeader] = useState(false)
  const [numberOfGroups, setNumberOfGroups] = useState(0)
  const [numberOfStudentsPerGroup, setNumberOfStudentsPerGroup] = useState(0)
  const [groupLeaderAssignmentMethod, setGroupLeaderAssignmentMethod] = useState(null)

  const handleNumberChange = (
    value,
    callback,
    newValue,
    max = Number.MAX_SAFE_INTEGER,
    min = 0
  ) => {
    if (!Number.isInteger(newValue)) {
      callback(value)
      return
    }
    newValue = Math.max(min, Math.min(max, newValue))
    callback(newValue)
  }

  const clearFields = () => {
    setGroupName('')
    setGroupStructure('')
    setAllowSelfSignup(false)
    setRequireSameSection(false)
    setAutoAssignGroupLeader(false)
    setNumberOfGroups(0)
    setNumberOfStudentsPerGroup(0)
    setGroupLeaderAssignmentMethod(null)
  }

  const submitForm = () => {
    onSubmit({
      groupName,
      groupStructure,
      allowSelfSignup,
      requireSameSection,
      autoAssignGroupLeader,
      numberOfGroups,
      numberOfStudentsPerGroup,
      groupLeaderAssignmentMethod,
    })
    clearFields()
    setShow(false)
  }

  return (
    <>
      <Modal
        open={show}
        onDismiss={() => setShow(false)}
        size="auto"
        label={I18N.t('Modal Dialog: New Group Set')}
        onOpen={() => defaultFocusElementRef.current?.focus()}
        shouldCloseOnDocumentClick={true}
        onExited={clearFields}
      >
        <Modal.Header>
          <CloseButton
            placement="end"
            offset="small"
            onClick={() => setShow(false)}
            screenReaderLabel={I18N.t('Close')}
          />
          <Heading>New Group Set</Heading>
        </Modal.Header>
        <Modal.Body>
          <FormFieldGroup description="">
            <TextInput
              renderLabel={I18N.t('Group Set Name')}
              value={groupName}
              onChange={event => setGroupName(event.target.value)}
              ref={defaultFocusElementRef}
            />
            <FormFieldGroup
              name="self-sign-up"
              description={
                <>
                  <Text>{I18N.t('Self Sign-Up')}</Text>
                  <Tooltip
                    renderTip={
                      <View display="block" maxWidth="20rem">
                        {I18N.t(
                          'This option allow students to organize themselves into groups. Though each student is limited to one group set, they will have the ability to move themselves from one group to another.'
                        )}
                      </View>
                    }
                    placement="top"
                    on={['click', 'hover', 'focus']}
                  >
                    <IconButton
                      renderIcon={IconInfoLine}
                      withBackground={false}
                      withBorder={false}
                      size="small"
                      screenReaderLabel={I18N.t('Toggle tooltip')}
                    />
                  </Tooltip>
                </>
              }
              rowSpacing="small"
            >
              <Checkbox
                label={I18N.t('Allow')}
                value="allow"
                checked={allowSelfSignup}
                onChange={event => {
                  const checked = event.target.checked
                  setRequireSameSection(checked && requireSameSection)
                  setAutoAssignGroupLeader(checked && autoAssignGroupLeader)
                  setGroupLeaderAssignmentMethod(checked ? groupLeaderAssignmentMethod : null)
                  setAllowSelfSignup(checked)
                }}
              />
              <Checkbox
                label={I18N.t('Require group members to be in the same section')}
                value="same-section"
                disabled={!allowSelfSignup}
                checked={requireSameSection}
                onChange={event => setRequireSameSection(event.target.checked)}
              />
            </FormFieldGroup>
            <SimpleSelect
              renderLabel={I18N.t('Group Structure')}
              value={groupStructure}
              onChange={(_event, {value}) => {
                setNumberOfGroups(value !== 'students-by-number-of-groups' ? 0 : numberOfGroups)
                setNumberOfStudentsPerGroup(
                  value !== 'number-of-students-per-group' ? 0 : numberOfStudentsPerGroup
                )
                setGroupStructure(value)
              }}
            >
              <SimpleSelect.Option id="create-later" value="create-later">
                {I18N.t('Create later')}
              </SimpleSelect.Option>
              <SimpleSelect.Option
                id="students-by-number-of-groups"
                value="students-by-number-of-groups"
              >
                {I18N.t('Split students by number of groups')}
              </SimpleSelect.Option>
              <SimpleSelect.Option
                id="number-of-students-per-group"
                value="number-of-students-per-group"
              >
                {I18N.t('Split by number of students per group')}
              </SimpleSelect.Option>
            </SimpleSelect>
            {groupStructure === 'students-by-number-of-groups' ? (
              <NumberInput
                renderLabel={I18N.t('Number of Groups')}
                value={numberOfGroups}
                // 200 is the default maximum number of groups in a set
                // TODO: fetch the real value from the backend ("max_groups_in_new_category" in Settings in Ruby)
                onChange={event =>
                  handleNumberChange(
                    numberOfGroups,
                    setNumberOfGroups,
                    Number(event.target.value),
                    200
                  )
                }
                onIncrement={() =>
                  handleNumberChange(numberOfGroups, setNumberOfGroups, numberOfGroups + 1, 200)
                }
                onDecrement={() =>
                  handleNumberChange(numberOfGroups, setNumberOfGroups, numberOfGroups - 1, 200)
                }
              />
            ) : groupStructure === 'number-of-students-per-group' ? (
              <NumberInput
                renderLabel={I18N.t('Number of Students Per Group')}
                value={numberOfStudentsPerGroup}
                // TODO: this should have a maximum of the number of students in the class
                onChange={event =>
                  handleNumberChange(
                    numberOfStudentsPerGroup,
                    setNumberOfStudentsPerGroup,
                    Number(event.target.value)
                  )
                }
                onIncrement={() =>
                  handleNumberChange(
                    numberOfStudentsPerGroup,
                    setNumberOfStudentsPerGroup,
                    numberOfStudentsPerGroup + 1
                  )
                }
                onDecrement={() =>
                  handleNumberChange(
                    numberOfStudentsPerGroup,
                    setNumberOfStudentsPerGroup,
                    numberOfStudentsPerGroup - 1
                  )
                }
              />
            ) : null}
            {allowSelfSignup ? (
              <FormFieldGroup description={I18N.t('Leadership')} rowSpacing="small">
                <Checkbox
                  label={I18N.t('Automatically assign a student group leader')}
                  value="auto-assign-leader"
                  checked={autoAssignGroupLeader}
                  onChange={event => {
                    const checked = event.target.checked
                    setGroupLeaderAssignmentMethod(checked ? groupLeaderAssignmentMethod : null)
                    setAutoAssignGroupLeader(checked)
                  }}
                />
                <RadioInputGroup
                  name="auto-assign-group-leader-settings"
                  description=""
                  disabled={!autoAssignGroupLeader}
                  value={groupLeaderAssignmentMethod}
                  onChange={event => setGroupLeaderAssignmentMethod(event.target.value)}
                >
                  <RadioInput
                    key="first"
                    value="first"
                    label={I18N.t('Set first student to join as group leader')}
                  />
                  <RadioInput
                    key="random"
                    value="random"
                    label={I18N.t('Set a random student as group leader')}
                  />
                </RadioInputGroup>
              </FormFieldGroup>
            ) : null}
          </FormFieldGroup>
        </Modal.Body>
        <Modal.Footer>
          <Button onClick={() => setShow(false)} margin="0 x-small 0 0">
            {I18N.t('Close')}
          </Button>
          <Button color="primary" type="submit" onClick={submitForm}>
            {I18N.t('Submit')}
          </Button>
        </Modal.Footer>
      </Modal>
    </>
  )
}

GroupCategoryModal.propTypes = {
  show: PropTypes.bool,
  setShow: PropTypes.func,
  onSubmit: PropTypes.func,
}

GroupCategoryModal.defaultProps = {
  show: false,
  setShow: () => {},
  onSubmit: () => {},
}
