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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconDragHandleLine, IconEditLine, IconOutcomesLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('rubrics-criteria-new-row')

type NewCriteriaRowProps = {
  rowIndex: number
  onEditCriterion: () => void
  onAddOutcome: () => void
}

export const NewCriteriaRow = ({rowIndex, onEditCriterion, onAddOutcome}: NewCriteriaRowProps) => {
  return (
    <View as="div" padding="medium small">
      <Flex>
        <Flex.Item align="start">
          <View as="div" cursor="pointer">
            <IconDragHandleLine />
          </View>
        </Flex.Item>
        <Flex.Item align="start">
          <View as="div" margin="xxx-small 0 0 small" themeOverride={{marginSmall: '1.5rem'}}>
            <Text weight="bold">{rowIndex}.</Text>
          </View>
        </Flex.Item>
        <Flex.Item margin="0 small" align="start" shouldGrow={true}>
          <Button
            // @ts-expect-error
            renderIcon={IconEditLine}
            onClick={onEditCriterion}
            data-testid="add-criterion-button"
          >
            {I18n.t('Draft New Criterion')}
          </Button>
          <Button
            id="create-from-outcome"
            // @ts-expect-error
            renderIcon={IconOutcomesLine}
            margin="0 0 0 small"
            onClick={onAddOutcome}
            data-testid="create-from-outcome-button"
          >
            {I18n.t('Create From Outcome')}
          </Button>
        </Flex.Item>
      </Flex>
    </View>
  )
}
