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

import {AssignmentAvailabilityWindow} from '../AssignmentAvailabilityWindow/AssignmentAvailabilityWindow'
import {AssignmentContext} from '../AssignmentContext/AssignmentContext'
import {AssignmentDueDate} from '../AssignmentDueDate/AssignmentDueDate'
import {nanoid} from 'nanoid'
import PropTypes from 'prop-types'
import React, {useMemo, useState} from 'react'
import {responsiveQuerySizes} from '../../utils/index'

import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Tray} from '@instructure/ui-tray'
import {CloseButton, CondensedButton} from '@instructure/ui-buttons'
import {Responsive} from '@instructure/ui-responsive'
import {DueDateTray} from '../DueDateTray/DueDateTray'
import {InlineList} from '@instructure/ui-list'

export function AssignmentAvailabilityContainer({...props}) {
  const [dueDateTrayOpen, setDueDateTrayOpen] = useState(false)

  let assignmentOverrides = props.assignment?.assignmentOverrides?.nodes || []

  const defaultDateSet =
    !!props.assignment?.dueAt || !!props.assignment?.lockAt || !!props.assignment?.unlockAt

  const singleOverrideWithNoDefault = !defaultDateSet && assignmentOverrides.length === 1

  if (defaultDateSet) {
    assignmentOverrides = props.isAdmin
      ? assignmentOverrides.concat({
          dueAt: props.assignment?.dueAt,
          unlockAt: props.assignment?.unlockAt,
          lockAt: props.assignment?.lockAt,
          title: assignmentOverrides.length > 0 ? I18n.t('Everyone Else') : I18n.t('Everyone'),
          id: props.assignment?.id
        })
      : [
          {
            dueAt: props.assignment?.dueAt,
            unlockAt: props.assignment?.unlockAt,
            lockAt: props.assignment?.lockAt,
            title: assignmentOverrides.length > 0 ? I18n.t('Everyone Else') : I18n.t('Everyone'),
            id: props.assignment?.id
          }
        ]
  }

  const singleDueDate = useMemo(
    () => (
      <Responsive
        match="media"
        query={responsiveQuerySizes({tablet: true, desktop: true})}
        props={{
          tablet: {
            dueDateMargin: 'none'
          },
          desktop: {
            dueDateMargin: '0 0 0 x-small'
          }
        }}
        render={(_responsiveProps, matches) => {
          const group = singleOverrideWithNoDefault ? assignmentOverrides[0]?.title : ''
          const availabilityInformation = singleOverrideWithNoDefault
            ? assignmentOverrides[0]
            : props.assignment

          return (
            <InlineList delimiter="none" itemSpacing="none">
              {[
                props.isAdmin && matches.includes('desktop') ? (
                  <AssignmentContext group={group} />
                ) : null,
                <AssignmentDueDate
                  dueDate={availabilityInformation?.dueAt}
                  onSetDueDateTrayOpen={setDueDateTrayOpen}
                />,
                (availabilityInformation.unlockAt || availabilityInformation.lockAt) &&
                matches.includes('desktop') ? (
                  <AssignmentAvailabilityWindow
                    availableDate={availabilityInformation.unlockAt}
                    untilDate={availabilityInformation.lockAt}
                  />
                ) : null
              ]
                .filter(item => item !== null)
                .map(item => (
                  <InlineList.Item key={`assignement-due-date-section-${nanoid()}`}>
                    <View display="inline-block">{item}</View>
                  </InlineList.Item>
                ))}
            </InlineList>
          )
        }}
      />
    ),
    [assignmentOverrides, props.assignment, props.isAdmin, singleOverrideWithNoDefault]
  )

  const multipleDueDates = useMemo(
    () => (
      <>
        <CondensedButton
          onClick={() => {
            setDueDateTrayOpen(true)
          }}
          data-testid="show-due-dates-button"
        >
          <Responsive
            match="media"
            query={responsiveQuerySizes({tablet: true, desktop: true})}
            props={{
              tablet: {
                text: I18n.t('Due Dates (%{dueDateCount})', {
                  dueDateCount: assignmentOverrides.length
                }),
                textSize: 'x-small'
              },
              desktop: {
                text: I18n.t('Show Due Dates (%{dueDateCount})', {
                  dueDateCount: assignmentOverrides.length
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
      </>
    ),
    [assignmentOverrides.length]
  )

  return (
    <>
      {props.isAdmin && assignmentOverrides.length > 1 ? multipleDueDates : singleDueDate}
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
            <DueDateTray assignmentOverrides={assignmentOverrides} />
          </Flex>
        </View>
      </Tray>
    </>
  )
}

AssignmentAvailabilityContainer.propTypes = {
  assignment: PropTypes.object,
  isAdmin: PropTypes.bool
}
