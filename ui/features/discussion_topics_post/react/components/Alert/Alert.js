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
import DateHelper from '../../../../../shared/datetime/dateHelper'

import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {Link} from '@instructure/ui-link'
import {View} from '@instructure/ui-view'
import {Tray} from '@instructure/ui-tray'
import {CloseButton} from '@instructure/ui-buttons'
import {Grid} from '@instructure/ui-grid'

export function Alert({...props}) {
  const [dueDateTrayOpen, setDueDateTrayOpen] = useState(false)

  const singleDueDate = useMemo(
    () => (
      <Flex.Item padding="x-small" shouldGrow align="start">
        <Text weight="light" size="small">
          {props.dueAtDisplayText}
        </Text>
      </Flex.Item>
    ),
    [props.dueAtDisplayText]
  )

  const multipleDueDates = useMemo(
    () => (
      <Flex.Item padding="x-small" shouldGrow align="start">
        <Link
          as="button"
          onClick={() => {
            setDueDateTrayOpen(true)
          }}
        >
          <Text>
            {I18n.t('Show Due Dates (%{dueDateCount})', {
              dueDateCount: props.assignmentOverrides.length
            })}
          </Text>
        </Link>
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
              <Grid>
                <Grid.Row>
                  <Grid.Col width={{small: 4, medium: 5, large: 2, xLarge: 6}}>
                    <Text size="large" weight="bold">
                      {I18n.t('Due At')}
                    </Text>
                  </Grid.Col>
                  <Grid.Col width={{small: 4, medium: 2, large: 4, xLarge: 1}}>
                    <Text size="large" weight="bold">
                      {I18n.t('For')}
                    </Text>
                  </Grid.Col>
                  <Grid.Col width={{small: 4, medium: 5, large: 3, xLarge: 6}}>
                    <Text size="large" weight="bold">
                      {I18n.t('Available From')}
                    </Text>
                  </Grid.Col>
                  <Grid.Col width={{small: 4, medium: 5, large: 2, xLarge: 6}}>
                    <Text size="large" weight="bold">
                      {I18n.t('Until')}
                    </Text>
                  </Grid.Col>
                </Grid.Row>
                {props.assignmentOverrides.map(item => (
                  <Grid.Row key={item.id}>
                    <Grid.Col width={{small: 4, medium: 5, large: 2, xLarge: 6}}>
                      <Text size="medium">
                        {item.dueAt
                          ? DateHelper.formatDatetimeForDiscussions(item.dueAt)
                          : I18n.t('No Due Date')}
                      </Text>
                    </Grid.Col>
                    <Grid.Col width={{small: 4, medium: 2, large: 4, xLarge: 1}}>
                      <Text size="medium">
                        {item.title.length < 34 ? item.title : `${item.title.slice(0, 32)}...`}
                      </Text>
                    </Grid.Col>
                    <Grid.Col width={{small: 4, medium: 5, large: 3, xLarge: 6}}>
                      <Text size="medium">
                        {item.unlockAt
                          ? DateHelper.formatDatetimeForDiscussions(item.unlockAt)
                          : I18n.t('No Start Date')}
                      </Text>
                    </Grid.Col>
                    <Grid.Col width={{small: 4, medium: 5, large: 2, xLarge: 6}}>
                      <Text size="medium">
                        {item.lockAt
                          ? DateHelper.formatDatetimeForDiscussions(item.lockAt)
                          : I18n.t('No End Date')}
                      </Text>
                    </Grid.Col>
                  </Grid.Row>
                ))}
              </Grid>
            </Flex>
          </View>
        </Tray>
      </Flex.Item>
    ),
    [dueDateTrayOpen, props.assignmentOverrides]
  )

  return (
    <Flex data-testid="graded-discussion-info">
      {props.canSeeMultipleDueDates && props.assignmentOverrides.length > 0
        ? multipleDueDates
        : singleDueDate}
      <Flex.Item padding="x-small" align="end">
        <Text weight="light" size="small">
          {I18n.t(
            {
              one: 'This is a graded discussion: %{count} point possible',
              other: 'This is a graded discussion: %{count} points possible'
            },
            {
              count: props.pointsPossible
            }
          )}
        </Text>
      </Flex.Item>
    </Flex>
  )
}

Alert.propTypes = {
  pointsPossible: PropTypes.number.isRequired,
  dueAtDisplayText: PropTypes.string.isRequired,
  assignmentOverrides: PropTypes.array.isRequired,
  canSeeMultipleDueDates: PropTypes.bool
}

export default Alert
