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

import I18n from 'i18n!discussion_posts'

import PropTypes from 'prop-types'
import React, {useMemo, useState} from 'react'
import {responsiveQuerySizes} from '../../utils'

import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Tray} from '@instructure/ui-tray'
import {CloseButton, CondensedButton} from '@instructure/ui-buttons'
import {Responsive} from '@instructure/ui-responsive'
import {DueDateTray} from '../DueDateTray/DueDateTray'

export function AssignmentDetails({...props}) {
  const [dueDateTrayOpen, setDueDateTrayOpen] = useState(false)

  const singleDueDate = useMemo(
    () => (
      <Flex.Item padding="x-small" shouldGrow align="start">
        <Text weight="normal" size="small">
          {props.dueAtDisplayText}
        </Text>
      </Flex.Item>
    ),
    [props.dueAtDisplayText]
  )

  const multipleDueDates = useMemo(
    () => (
      <Flex.Item padding="xx-small" shouldGrow align="start" overflowY="hidden">
        <CondensedButton
          onClick={() => {
            setDueDateTrayOpen(true)
          }}
          data-testid="show-due-dates-button"
        >
          <Responsive
            match="media"
            query={responsiveQuerySizes({mobile: true, desktop: true})}
            props={{
              mobile: {
                text: I18n.t('Due Dates (%{dueDateCount})', {
                  dueDateCount: props.assignmentOverrides.length
                }),
                textSize: 'x-small'
              },
              desktop: {
                text: I18n.t('Show Due Dates (%{dueDateCount})', {
                  dueDateCount: props.assignmentOverrides.length
                }),
                textSize: 'small'
              }
            }}
            render={responsiveProps => (
              <Text weight="bold" size={responsiveProps.textSize}>
                {responsiveProps.text}
              </Text>
            )}
          />
        </CondensedButton>
        <Tray open={dueDateTrayOpen} size="large" placement="end" label="Due Dates">
          <View as="div" padding="medium">
            <Flex direction="column">
              <Flex.Item>
                <CloseButton
                  placement="end"
                  offset="small"
                  screenReaderLabel="Close"
                  onClick={() => {
                    setDueDateTrayOpen(false)
                  }}
                />
              </Flex.Item>
              <Flex.Item padding="none none medium none" shouldGrow shouldShrink>
                <Text size="x-large" weight="bold" data-testid="due-dates-tray-heading">
                  {I18n.t('Due Dates')}
                </Text>
              </Flex.Item>
              <DueDateTray assignmentOverrides={props.assignmentOverrides} />
            </Flex>
          </View>
        </Tray>
      </Flex.Item>
    ),
    [dueDateTrayOpen, props.assignmentOverrides]
  )

  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, desktop: true})}
      props={{
        mobile: {
          text: I18n.t(
            {
              one: '1 point',
              other: '%{count} points'
            },
            {
              count: props.pointsPossible
            }
          ),
          textSize: 'x-small'
        },
        desktop: {
          text: I18n.t(
            {
              one: '1 point possible',
              other: '%{count} points possible'
            },
            {
              count: props.pointsPossible
            }
          ),
          textSize: 'small'
        }
      }}
      render={responsiveProps => (
        <Flex data-testid="graded-discussion-info">
          {props.canSeeMultipleDueDates && props.assignmentOverrides.length > 0
            ? multipleDueDates
            : singleDueDate}
          <Flex.Item shouldShrink align="end" overflowY="hidden">
            <Text weight="normal" size={responsiveProps.textSize}>
              {responsiveProps.text}
            </Text>
          </Flex.Item>
        </Flex>
      )}
    />
  )
}

AssignmentDetails.propTypes = {
  pointsPossible: PropTypes.number.isRequired,
  dueAtDisplayText: PropTypes.string.isRequired,
  assignmentOverrides: PropTypes.array.isRequired,
  canSeeMultipleDueDates: PropTypes.bool
}

export default AssignmentDetails
