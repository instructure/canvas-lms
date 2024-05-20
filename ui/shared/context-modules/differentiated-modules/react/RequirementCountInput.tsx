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

import React, {createRef, useEffect} from 'react'
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Checkbox} from '@instructure/ui-checkbox'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('differentiated_modules')

export interface RequirementCountInputProps {
  requirementCount: 'all' | 'one'
  requireSequentialProgress: boolean
  onChangeRequirementCount: (type: 'all' | 'one') => void
  onToggleSequentialProgress: () => void
  focus?: boolean
}

export default function RequirementCountInput({
  requirementCount,
  requireSequentialProgress,
  onChangeRequirementCount,
  onToggleSequentialProgress,
  focus = false,
}: RequirementCountInputProps) {
  const defaultRadioInput = createRef<RadioInput>()

  useEffect(() => {
    // Focus radio button on load
    focus && defaultRadioInput.current?.focus()
  }, [focus, defaultRadioInput])

  return (
    <RadioInputGroup
      name="requirement-count"
      description={<ScreenReaderContent>{I18n.t('Select Requirement Count')}</ScreenReaderContent>}
    >
      <Flex>
        <Flex.Item align="start">
          <RadioInput
            ref={defaultRadioInput}
            data-testid="complete-all-radio"
            checked={requirementCount === 'all'}
            value="all"
            label={<ScreenReaderContent>{I18n.t('Complete all')}</ScreenReaderContent>}
            onClick={() => onChangeRequirementCount('all')}
          />
        </Flex.Item>
        <Flex.Item>
          <Text>{I18n.t('Complete all')}</Text>
          <View as="div">
            <Text color="secondary" size="small">
              {I18n.t('Students must complete all of these requirements.')}
            </Text>
          </View>
          {requirementCount === 'all' && (
            <View as="div" margin="small small 0 0">
              <Checkbox
                data-testid="sequential-progress-checkbox"
                checked={requireSequentialProgress}
                onChange={onToggleSequentialProgress}
                label={I18n.t('Students must move through requirements in sequential order')}
              />
            </View>
          )}
        </Flex.Item>
      </Flex>
      <Flex>
        <Flex.Item align="start">
          <RadioInput
            data-testid="complete-one-radio"
            checked={requirementCount === 'one'}
            value="one"
            label={<ScreenReaderContent>{I18n.t('Complete one')}</ScreenReaderContent>}
            onClick={() => onChangeRequirementCount('one')}
          />
        </Flex.Item>
        <Flex.Item>
          <Text>{I18n.t('Complete one')}</Text>
          <View as="div">
            <Text color="secondary" size="small">
              {I18n.t('Students must complete one of these requirements.')}
            </Text>
          </View>
        </Flex.Item>
      </Flex>
    </RadioInputGroup>
  )
}
