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

import React, {useEffect, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {translateState} from './EnrollmentTreeGroup'
import {createAnalyticPropsGenerator} from './util/analytics'
import {
  ENROLLMENT_TREE_ICON_OFFSET,
  ENROLLMENT_TREE_SPACING,
  MODULE_NAME,
  type NodeStructure,
} from './types'
import type {Spacing} from '@instructure/emotion'
import {View} from '@instructure/ui-view'
import ToolTipWrapper from './ToolTipWrapper'
import RoleMismatchToolTip from './RoleMismatchToolTip'

const I18n = useI18nScope('temporary_enrollment')

// initialize analytics props
const analyticProps = createAnalyticPropsGenerator(MODULE_NAME)

interface Props extends NodeStructure {
  indent: Spacing
  updateCheck?: Function
  workflowState?: string
}

export function EnrollmentTreeItem(props: Props) {
  const [checked, setChecked] = useState(false)

  useEffect(() => {
    if (props.isCheck !== undefined) {
      setChecked(props.isCheck)
    }
  }, [props.isCheck])

  const handleCheckboxChange = () => {
    setChecked(!checked)

    if (props.updateCheck) {
      props.updateCheck(props, !props.isCheck)
    }
  }

  const renderRow = () => {
    return (
      <View as="div" key={props.id} padding={props.indent}>
        <Flex alignItems="start" gap="x-small">
          <Flex.Item shouldShrink={true}>
            <Checkbox
              data-testid={'check-' + props.id}
              label={<Text weight="bold">{props.label}</Text>}
              checked={checked}
              onChange={handleCheckboxChange}
              {...analyticProps('Course')}
            />
          </Flex.Item>
          {props.isMismatch ? (
            <Flex.Item>
              <ToolTipWrapper positionTop={ENROLLMENT_TREE_ICON_OFFSET}>
                <RoleMismatchToolTip testId={'tip-' + props.id} />
              </ToolTipWrapper>
            </Flex.Item>
          ) : null}
        </Flex>
        {props.workflowState ? (
          <div style={{paddingLeft: ENROLLMENT_TREE_SPACING}}>
            <Text size="small">
              {I18n.t('course status: %{state}', {
                state: translateState(props.workflowState),
              })}
            </Text>
          </div>
        ) : null}
      </View>
    )
  }

  return renderRow()
}
