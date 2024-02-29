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
import {useScope as useI18nScope} from '@canvas/i18n'
import {Button, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {
  IconDragHandleLine,
  IconDuplicateLine,
  IconEditLine,
  IconOutcomesLine,
  IconTrashLine,
} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {Pill} from '@instructure/ui-pill'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('rubrics-criteria-new-row')

type NewCriteriaRowProps = {
  rowIndex: number
  onEditCriterion: () => void
}

export const NewCriteriaRow = ({rowIndex, onEditCriterion}: NewCriteriaRowProps) => {
  return (
    <View>
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
            renderIcon={IconEditLine}
            onClick={onEditCriterion}
            data-testid="add-criterion-button"
          >
            {I18n.t('Draft New Criterion')}
          </Button>
          <Button renderIcon={IconOutcomesLine} margin="0 0 0 small">
            {I18n.t('Create From Outcome')}
          </Button>
        </Flex.Item>
        <Flex.Item align="start">
          <Pill
            color="info"
            themeOverride={{
              background: '#C7CDD1',
              infoColor: 'white',
            }}
          >
            <Text size="x-small">-- pts</Text>
          </Pill>
          <View as="span" margin="0 0 0 medium">
            <IconButton
              disabled={true}
              withBackground={false}
              withBorder={false}
              screenReaderLabel=""
              themeOverride={{smallHeight: '18px'}}
              size="small"
            >
              <IconEditLine />
            </IconButton>
          </View>

          <View as="span" margin="0 0 0 medium">
            <IconButton
              disabled={true}
              withBackground={false}
              withBorder={false}
              screenReaderLabel=""
              themeOverride={{smallHeight: '18px'}}
              size="small"
            >
              <IconTrashLine />
            </IconButton>
          </View>

          <View as="span" margin="0 0 0 medium">
            <IconButton
              disabled={true}
              withBackground={false}
              withBorder={false}
              screenReaderLabel=""
              themeOverride={{smallHeight: '18px'}}
              size="small"
            >
              <IconDuplicateLine />
            </IconButton>
          </View>
        </Flex.Item>
      </Flex>
    </View>
  )
}
