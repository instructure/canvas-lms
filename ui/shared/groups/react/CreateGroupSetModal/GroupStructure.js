/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import React, {useContext} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {RadioInput} from '@instructure/ui-radio-input'
import {Checkbox} from '@instructure/ui-checkbox'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {func, string} from 'prop-types'
import {GroupContext, formatMessages, SPLIT} from './context'

const I18n = useI18nScope('groups')

const I18NSPLIT_PATTERN = /(.+)\s+ZZZ\s(.+)/

const GroupStructureSelfSignup = ({onChange, errormsg}) => {
  const {createGroupCount, groupLimit} = useContext(GroupContext)

  // Split up the I18n strings so we can put TextInputs in the middle of them
  const createGroups = I18n.t('Create %{number_of_groups} groups now', {
    number_of_groups: 'ZZZ'
  }).match(I18NSPLIT_PATTERN)
  const limitGroupSize = I18n.t('Limit groups to %{group_limit} members', {
    group_limit: 'ZZZ'
  }).match(I18NSPLIT_PATTERN)

  return (
    <FormFieldGroup
      description={
        <ScreenReaderContent>{I18n.t('Group structure for self-signup')}</ScreenReaderContent>
      }
      messages={formatMessages(errormsg)}
      rowSpacing="small"
    >
      <View>
        <Text>{createGroups[1]}</Text>
        &nbsp;
        <TextInput
          display="inline-block"
          width="3rem"
          size="x-small"
          id="textinput-create-groups-now"
          value={createGroupCount}
          renderLabel={
            <ScreenReaderContent>{I18n.t('Number of groups to create')}</ScreenReaderContent>
          }
          onChange={(_e, val) => {
            onChange('createGroupCount', val)
          }}
        />
        &nbsp;
        <Text>{createGroups[2]}</Text>
      </View>
      <View>
        <Text>{limitGroupSize[1]}</Text>
        &nbsp;
        <TextInput
          display="inline-block"
          width="3rem"
          size="x-small"
          id="textinput-limit-group-size"
          value={groupLimit}
          renderLabel={<ScreenReaderContent>{I18n.t('Group Size Limit')}</ScreenReaderContent>}
          onChange={(_e, val) => {
            onChange('groupLimit', val)
          }}
        />
        &nbsp;
        <Text>{limitGroupSize[2]}</Text>
        &nbsp;
        <Text size="small" color="secondary">
          ({I18n.t('Leave blank for no limit')})
        </Text>
      </View>
    </FormFieldGroup>
  )
}

const GroupStructureNoSelfSignup = ({onChange, errormsg}) => {
  const {splitGroups, bySection, createGroupCount, createGroupMemberCount} =
    useContext(GroupContext)

  // Split up the I18n strings so we can put TextInputs in the middle of them
  const createGroups = I18n.t('Split students into %{num_groups} groups', {
    num_groups: 'ZZZ'
  }).match(I18NSPLIT_PATTERN)
  const createMemberGroups = I18n.t(
    'Split students into groups with %{num_members} students per group',
    {
      num_members: 'ZZZ'
    }
  ).match(I18NSPLIT_PATTERN)

  return (
    <FormFieldGroup
      description={<ScreenReaderContent>{I18n.t('Group structure')}</ScreenReaderContent>}
      messages={formatMessages(errormsg)}
      rowSpacing="small"
    >
      <RadioInput
        label={
          <div display="inline-block">
            <Text>{createGroups[1]}</Text>
            &nbsp;
            <TextInput
              display="inline-block"
              width="3rem"
              size="x-small"
              value={createGroupCount}
              id="textinput-create-groups-count"
              renderLabel={<ScreenReaderContent>{I18n.t('Number of groups')}</ScreenReaderContent>}
              disabled={splitGroups !== SPLIT.byGroupCount}
              onChange={(_e, val) => {
                onChange('createGroupCount', val)
              }}
            />
            &nbsp;
            <Text>{createGroups[2]}</Text>
          </div>
        }
        value={SPLIT.byGroupCount}
        data-testid="radio-button-split-groups"
        checked={splitGroups === SPLIT.byGroupCount}
        onChange={e => {
          onChange('splitGroups', e.target.value)
        }}
      />

      <RadioInput
        label={
          <div display="inline-block">
            <Text>{createMemberGroups[1]}</Text>
            &nbsp;
            <TextInput
              display="inline-block"
              width="3rem"
              size="x-small"
              value={createGroupMemberCount}
              id="textinput-create-members-count"
              renderLabel={
                <ScreenReaderContent>{I18n.t('Number of members per group')}</ScreenReaderContent>
              }
              disabled={splitGroups !== SPLIT.byMemberCount}
              onChange={(_e, val) => {
                onChange('createGroupMemberCount', val)
              }}
            />
            &nbsp;
            <Text>{createMemberGroups[2]}</Text>
          </div>
        }
        value={SPLIT.byMemberCount}
        data-testid="radio-button-group-members"
        checked={splitGroups === SPLIT.byMemberCount}
        onChange={e => {
          onChange('splitGroups', e.target.value)
        }}
      />

      {splitGroups !== SPLIT.off && (
        <Checkbox
          checked={bySection}
          label={I18n.t('Require group members to be in the same section')}
          onChange={e => {
            onChange('bySection', e.target.checked)
          }}
        />
      )}

      <RadioInput
        label={I18n.t('I’ll create groups later')}
        value={SPLIT.off}
        data-testid="radio-button-create-later"
        checked={splitGroups === SPLIT.off}
        onChange={e => {
          onChange('splitGroups', e.target.value)
        }}
      />
    </FormFieldGroup>
  )
}

export const GroupStructure = ({onChange, errormsg}) => {
  /* eslint-disable prettier/prettier */
  const {
    selfSignup,
    createGroupCount,
    createGroupMemberCount,
    bySection,
    splitGroups,
    groupLimit
  } = useContext(GroupContext)
  /* eslint-enable prettier/prettier */

  function handleChange(key, val) {
    let result = {createGroupCount, createGroupMemberCount, bySection, splitGroups, groupLimit}
    result[key] = val
    if (key === 'splitGroups') {
      if (val === SPLIT.byGroupCount) result.createGroupMemberCount = '0'
      if (val === SPLIT.byMemberCount) result.createGroupCount = '0'
      if (val === SPLIT.off)
        result = {...result, bySection: false, createGroupMemberCount: '0', createGroupCount: '0'}
    }
    onChange(result)
  }

  return (
    <Flex>
      <Flex.Item padding="none medium none none">
        <Text>{I18n.t('Group Structure')}</Text>
      </Flex.Item>
      <Flex.Item shouldGrow>
        {selfSignup ? (
          <GroupStructureSelfSignup onChange={handleChange} errormsg={errormsg} />
        ) : (
          <GroupStructureNoSelfSignup onChange={handleChange} errormsg={errormsg} />
        )}
      </Flex.Item>
    </Flex>
  )
}

GroupStructure.propTypes = {
  onChange: func.isRequired,
  errormsg: string
}
