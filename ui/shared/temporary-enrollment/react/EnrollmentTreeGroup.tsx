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

import {IconButton} from '@instructure/ui-buttons'
import React from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {IconArrowOpenDownSolid, IconArrowOpenEndSolid} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {EnrollmentTreeItem} from './EnrollmentTreeItem'
import {NodeStructure} from './EnrollmentTree'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import RoleMismatchToolTip from './RoleMismatchToolTip'
import {createAnalyticPropsGenerator} from './util/analytics'
import {MODULE_NAME} from './types'

const I18n = useI18nScope('temporary_enrollment')

// initialize analytics props
const analyticProps = createAnalyticPropsGenerator(MODULE_NAME)

interface Props extends NodeStructure {
  indent: any
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
    case 'deleted':
      return I18n.t('deleted')
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

  const renderChildren = () => {
    const childRows = []
    if (props.isToggle) {
      // if parent is a role
      if (props.id.startsWith('r')) {
        for (const course of props.children) {
          if (course.children.length > 1) {
            childRows.push(
              <EnrollmentTreeGroup
                key={course.id}
                indent="0 0 0 medium"
                id={course.id}
                label={course.label}
                isCheck={course.isCheck}
                isToggle={course.isToggle}
                updateCheck={props.updateCheck}
                updateToggle={props.updateToggle}
                isMixed={course.isMixed}
                isMismatch={course.isMismatch}
                workState={course.workState}
                parent={course.parent}
              >
                {course.children}
              </EnrollmentTreeGroup>
            )
          } else {
            const label = course.label + ' - ' + course.children[0].label
            childRows.push(
              <EnrollmentTreeItem
                key={course.id}
                indent="0 0 0 medium"
                id={course.id}
                label={label}
                isCheck={course.isCheck}
                updateCheck={props.updateCheck}
                isMixed={false}
                workState={course.workState}
                parent={course.parent}
                isMismatch={course.isMismatch}
              >
                {[]}
              </EnrollmentTreeItem>
            )
          }
        }
      } else {
        for (const section of props.children) {
          childRows.push(
            <EnrollmentTreeItem
              key={section.id}
              indent="0 0 0 x-large"
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
          )
        }
      }
    }
    return childRows
  }

  const renderRow = () => {
    const toggleIcon = props.isToggle ? IconArrowOpenDownSolid : IconArrowOpenEndSolid

    return (
      <>
        <Flex key={props.id} padding="x-small" as="div" alignItems="center">
          <Flex.Item margin={props.indent}>
            <Checkbox
              data-testid={'check ' + props.id}
              label=""
              size="large"
              checked={props.isCheck}
              indeterminate={props.isMixed}
              onChange={handleCheckboxChange}
              {...analyticProps('Enrollment')}
            />
          </Flex.Item>
          <Flex.Item margin="0 0 0 x-small">
            <IconButton
              withBorder={false}
              withBackground={false}
              onClick={handleIconButtonClick}
              // value={props.isToggle}  <--- this is an invalid prop to IconButton. FIXME
              screenReaderLabel={I18n.t('Toggle group %{group}', {group: props.label})}
              {...analyticProps('Group')}
            >
              {toggleIcon}
            </IconButton>
          </Flex.Item>
          <Flex.Item margin="0 0 0 x-small">
            <Text>{props.label}</Text>
          </Flex.Item>
          {props.isMismatch ? (
            <Flex.Item>
              <RoleMismatchToolTip />
            </Flex.Item>
          ) : null}
          {props.workState ? (
            <Flex.Item margin="0 large">
              <Text weight="light">
                {I18n.t('course status: %{state}', {state: translateState(props.workState)})}
              </Text>
            </Flex.Item>
          ) : null}
        </Flex>
        {renderChildren()}
      </>
    )
  }

  return renderRow()
}
