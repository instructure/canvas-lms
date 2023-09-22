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

import React, {useState} from 'react'
import {Flex} from '@instructure/ui-flex'
import Footer from './Footer'
// @ts-expect-error -- TODO: remove once we're on InstUI 8
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import {Text} from '@instructure/ui-text'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import AssigneeSelector from './AssigneeSelector'

const I18n = useI18nScope('differentiated_modules')

// Doing this to avoid TS2339 errors-- remove once we're on InstUI 8
const {Item: FlexItem} = Flex as any

export interface AssignToPanelProps {
  height: string
  onDismiss: () => void
}

interface Option {
  value: string
  getLabel: () => string
  getDescription: () => string
}

const OPTIONS: Option[] = [
  {
    value: 'everyone',
    getLabel: () => I18n.t('Everyone'),
    getDescription: () => I18n.t('This module will be visible to everyone.'),
  },
  {
    value: 'custom',
    getLabel: () => I18n.t('Custom Access'),
    getDescription: () =>
      I18n.t('Create custom access and optionally set Lock Until date for each group.'),
  },
]

export default function AssignToPanel({height, onDismiss}: AssignToPanelProps) {
  const [selectedOption, setSelectedOption] = useState<string>(OPTIONS[0].value)

  return (
    <Flex direction="column" justifyItems="start" height={height}>
      <FlexItem padding="medium medium small">
        <Text>
          {I18n.t('By default everyone in this course has assigned access to this module.')}
        </Text>
      </FlexItem>
      <FlexItem padding="x-small medium" overflowX="hidden">
        <RadioInputGroup description={I18n.t('Select Access Type')} name="access_type">
          {OPTIONS.map(option => (
            <Flex key={option.value}>
              <FlexItem align="start">
                <View as="div" margin="none">
                  <RadioInput
                    data-testid={`${option.value}-option`}
                    value={option.value}
                    checked={selectedOption === option.value}
                    onClick={() => setSelectedOption(option.value)}
                    label={<ScreenReaderContent>{option.getLabel()}</ScreenReaderContent>}
                  />
                </View>
              </FlexItem>
              <FlexItem>
                <View as="div" margin="none">
                  <Text>{option.getLabel()}</Text>
                </View>
                <View as="div" margin="none">
                  <Text color="secondary" size="small">
                    {option.getDescription()}
                  </Text>
                </View>
                {option.value === OPTIONS[1].value && selectedOption === OPTIONS[1].value && (
                  <View as="div" margin="small large none none">
                    <AssigneeSelector />
                  </View>
                )}
              </FlexItem>
            </Flex>
          ))}
        </RadioInputGroup>
      </FlexItem>
      <FlexItem margin="auto none none none">
        <Footer onDismiss={onDismiss} onUpdate={() => {}} />
      </FlexItem>
    </Flex>
  )
}
