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
import {Flex} from '@instructure/ui-flex'
import {Checkbox} from '@instructure/ui-checkbox'
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {func} from 'prop-types'
import {GroupContext, SPLIT} from './context'

const I18n = useI18nScope('groups')

export const Leadership = ({onChange}) => {
  const {enableAutoLeader, autoLeaderType, selfSignup, splitGroups} = useContext(GroupContext)

  function handleEnableChange(event) {
    onChange({autoLeaderType, enableAutoLeader: event.target.checked})
  }

  function handleTypeChange(_event, value) {
    onChange({autoLeaderType: value, enableAutoLeader})
  }

  if (!selfSignup && splitGroups === SPLIT.off) return null

  return (
    <Flex data-testid="group-leadership-controls">
      <Flex.Item padding="none medium none none">
        <Text>{I18n.t('Leadership')}</Text>
      </Flex.Item>
      <Flex.Item shouldGrow={true}>
        <Flex direction="column">
          <Flex.Item padding="x-small">
            <Checkbox
              data-testid="enable-auto"
              checked={enableAutoLeader}
              label={I18n.t('Automatically assign a student group leader')}
              onChange={handleEnableChange}
            />
          </Flex.Item>
          <Flex.Item padding="x-small">
            <RadioInputGroup
              onChange={handleTypeChange}
              name="select-leader-method"
              description={
                <ScreenReaderContent>{I18n.t('Group leader selection method')}</ScreenReaderContent>
              }
              value={autoLeaderType}
              disabled={!enableAutoLeader}
            >
              <RadioInput
                value="FIRST"
                data-testid="first"
                label={I18n.t('Set first student to join as group leader')}
              />
              <RadioInput
                value="RANDOM"
                data-testid="random"
                label={I18n.t('Set a random student as group leader')}
              />
            </RadioInputGroup>
          </Flex.Item>
        </Flex>
      </Flex.Item>
    </Flex>
  )
}

Leadership.propTypes = {
  onChange: func.isRequired,
}
