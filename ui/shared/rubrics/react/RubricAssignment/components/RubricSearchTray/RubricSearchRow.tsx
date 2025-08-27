/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {RadioInput} from '@instructure/ui-radio-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {IconArrowOpenEndLine} from '@instructure/ui-icons'
import {Rubric} from '../../../types/rubric'
import {possibleString} from '../../../Points'
import {useScope as createI18nScope} from '@canvas/i18n'
import {IconButton} from '@instructure/ui-buttons'

const I18n = createI18nScope('enhanced-rubrics-assignment-search')

type RubricSearchRowProps = {
  checked: boolean
  rubric: Rubric
  onPreview: (rubric: Rubric) => void
  onSelect: () => void
}
export const RubricSearchRow = ({checked, rubric, onPreview, onSelect}: RubricSearchRowProps) => {
  const possibleText = () => {
    if (rubric.hidePoints) {
      return I18n.t('Unscored')
    }

    return possibleString(rubric.pointsPossible)
  }

  return (
    <View as="div" margin="medium 0 0">
      <Flex>
        <Flex.Item align="start" margin="xxx-small 0 0">
          <RadioInput
            label={
              <ScreenReaderContent>
                {I18n.t('select %{title}', {title: rubric.title})}
              </ScreenReaderContent>
            }
            onChange={onSelect}
            checked={checked}
          />
        </Flex.Item>
        <Flex.Item shouldGrow={true} align="start" margin="0 0 0 xx-small">
          <View as="div">
            <Text data-testid="rubric-search-row-title">{rubric.title}</Text>
          </View>
          <View as="div">
            <Text size="small" data-testid="rubric-search-row-data">
              {possibleText()} | {rubric.criteriaCount} {I18n.t('criterion')}
            </Text>
          </View>
        </Flex.Item>
        <Flex.Item align="start">
          <IconButton
            data-testid="rubric-preview-btn"
            screenReaderLabel={I18n.t('Preview Rubric')}
            onClick={() => onPreview(rubric)}
            withBackground={false}
            withBorder={false}
          >
            <IconArrowOpenEndLine />
          </IconButton>
        </Flex.Item>
      </Flex>
      <View as="hr" margin="medium 0 0" />
    </View>
  )
}
