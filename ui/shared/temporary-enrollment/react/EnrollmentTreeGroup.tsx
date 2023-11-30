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
import {IconButton} from '@instructure/ui-buttons'
import {useScope as useI18nScope} from '@canvas/i18n'
import {IconArrowOpenDownSolid, IconArrowOpenEndSolid} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {EnrollmentTreeItem} from './EnrollmentTreeItem'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {createAnalyticPropsGenerator} from './util/analytics'
import type {NodeStructure} from './types'
import {ENROLLMENT_TREE_ICON_OFFSET, ENROLLMENT_TREE_SPACING, MODULE_NAME} from './types'
import type {Spacing} from '@instructure/emotion'
import ToolTipWrapper from './ToolTipWrapper'
import RoleMismatchToolTip from './RoleMismatchToolTip'

const I18n = useI18nScope('temporary_enrollment')

// initialize analytics props
const analyticProps = createAnalyticPropsGenerator(MODULE_NAME)

interface Props extends NodeStructure {
  indent: Spacing
  updateCheck: Function
  updateToggle: Function
}

export function translateState(workflow: string) {
  switch (workflow) {
    case 'created':
    case 'claimed':
    case 'unpublished':
      return I18n.t('unpublished')
    case 'available':
      return I18n.t('published')
    case 'completed':
      return I18n.t('completed')
    default:
      return I18n.t('unknown')
  }
}

export function EnrollmentTreeGroup(props: Props) {
  const handleCheckboxChange = () => {
    if (props.updateCheck) {
      props.updateCheck(props, !props.isCheck)
    }
  }

  const handleIconButtonClick = () => {
    props.updateToggle(props, !props.isToggle)
  }

  const renderChildren = (): {elements: JSX.Element | undefined; count: number} => {
    const childRows: JSX.Element[] = []
    if (props.isToggle) {
      // if parent is a role
      if (props.id.startsWith('r')) {
        for (const course of props.children as NodeStructure[]) {
          if (course.children.length === 0) return {elements: undefined, count: 0}
          if (course.children.length > 1) {
            childRows.push(
              <Flex.Item key={course.id} shouldGrow={true} overflowY="visible">
                <EnrollmentTreeGroup
                  indent="0"
                  id={course.id}
                  label={course.label}
                  isCheck={course.isCheck}
                  isToggle={course.isToggle}
                  updateCheck={props.updateCheck}
                  updateToggle={props.updateToggle}
                  isMixed={course.isMixed}
                  isMismatch={course.isMismatch}
                  workflowState={course.workflowState}
                  parent={course.parent}
                >
                  {course.children}
                </EnrollmentTreeGroup>
              </Flex.Item>
            )
          } else {
            const label = course.label + ' - ' + course.children[0].label
            childRows.push(
              <Flex.Item key={course.id} shouldGrow={true} overflowY="visible">
                <EnrollmentTreeItem
                  indent="0 0 0 large"
                  id={course.id}
                  label={label}
                  isCheck={course.isCheck}
                  updateCheck={props.updateCheck}
                  isMixed={false}
                  workflowState={course.workflowState}
                  parent={course.parent}
                  isMismatch={course.isMismatch}
                >
                  {[]}
                </EnrollmentTreeItem>
              </Flex.Item>
            )
          }
        }
      } else {
        for (const section of props.children) {
          childRows.push(
            <Flex.Item key={section.id} shouldGrow={true} overflowY="visible">
              <EnrollmentTreeItem
                indent="0 0 0 large"
                id={section.id}
                label={section.label}
                isCheck={section.isCheck}
                updateCheck={props.updateCheck}
                isMixed={false}
                parent={section.parent}
                isMismatch={section.isMismatch}
              >
                {[]}
              </EnrollmentTreeItem>
            </Flex.Item>
          )
        }
      }
    }

    return {
      elements: (
        <Flex gap="xx-small" direction="column">
          {childRows}
        </Flex>
      ),
      count: childRows.length,
    }
  }

  const renderRow = () => {
    const {elements, count} = renderChildren()

    return (
      <Flex key={props.id} gap="xx-small" direction="column">
        <Flex.Item overflowY="visible">
          <Flex padding={props.indent} alignItems="start" gap="x-small">
            <Flex.Item>
              <div style={{marginTop: ENROLLMENT_TREE_ICON_OFFSET}}>
                <IconButton
                  withBorder={false}
                  withBackground={false}
                  onClick={handleIconButtonClick}
                  size="small"
                  screenReaderLabel={I18n.t('Toggle group %{group}', {group: props.label})}
                  {...analyticProps('Group')}
                  aria-expanded={props.isToggle}
                >
                  {props.isToggle ? IconArrowOpenDownSolid : IconArrowOpenEndSolid}
                </IconButton>
              </div>
            </Flex.Item>
            <Flex.Item shouldShrink={true}>
              <Flex alignItems="start" gap="x-small">
                <Flex.Item shouldShrink={true}>
                  <Checkbox
                    data-testid={'check-' + props.id}
                    label={<Text weight="bold">{props.label}</Text>}
                    checked={props.isCheck}
                    indeterminate={props.isMixed}
                    onChange={handleCheckboxChange}
                    {...analyticProps('Enrollment')}
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
            </Flex.Item>
          </Flex>
        </Flex.Item>
        {count > 0 ? (
          <Flex.Item overflowY="visible">
            <div style={{paddingLeft: ENROLLMENT_TREE_SPACING}}>{elements}</div>
          </Flex.Item>
        ) : null}
      </Flex>
    )
  }

  return renderRow()
}
