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

import {useScope as createI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React, {useMemo, useState} from 'react'

import {Link} from '@instructure/ui-link'
import {Responsive} from '@instructure/ui-responsive'
import {Text} from '@instructure/ui-text'

import {AssignmentAvailabilityWindow} from '../AssignmentAvailabilityWindow/AssignmentAvailabilityWindow'
import {DiscussionAvailabilityTray} from '../DiscussionAvailabilityTray/DiscussionAvailabilityTray'
import {responsiveQuerySizes} from '../../utils/index'
import {TrayDisplayer} from '../TrayDisplayer/TrayDisplayer'
import {Flex} from '@instructure/ui-flex'

const I18n = createI18nScope('discussion_posts')

export function DiscussionAvailabilityContainer({...props}) {
  const [availabilityTrayOpen, setAvailabilityTrayOpen] = useState(false)
  const prefixText = useMemo(
    () =>
      props.anonymousState === 'full_anonymity'
        ? I18n.t('Anonymous Discussion')
        : props.anonymousState === 'partial_anonymity'
          ? I18n.t('Partially Anonymous Discussion')
          : null,
    [props.anonymousState],
  )

  const availabilities = useMemo(() => {
    let selectedAvailabilities = []
    let haveGroupsOverrideType = false
    if (!props.groupSet) {
      selectedAvailabilities = props.courseSections.length
        ? JSON.parse(JSON.stringify(props.courseSections))
        : [{userCount: props.totalUserCount, name: I18n.t('All Sections'), id: '1'}]
    } else if (props.groupSet.currentGroup) {
      selectedAvailabilities = JSON.parse(JSON.stringify([props.groupSet.currentGroup]))
      haveGroupsOverrideType = true
    } else if (props.groupSet?.groups) {
      selectedAvailabilities = JSON.parse(JSON.stringify(props.groupSet.groups))
      haveGroupsOverrideType = true
    } else {
      selectedAvailabilities = [
        {userCount: props.totalUserCount, name: props.groupSet.name, id: '1'},
      ]
    }

    if (props.assignment) {
      // Gets all assignment overrides if is graded
      const overrides = props.assignment.assignmentOverrides?.nodes || []
      selectedAvailabilities.forEach(availability => {
        // Searches for a group override that has the same id in assignmentOverrides
        const foundOverride =
          haveGroupsOverrideType &&
          overrides.find(
            override =>
              override.set.__typename === 'Group' && override.set._id === availability._id,
          )
        // If we don't find a matching override we'll use the 'Everyone' dates, if there is
        // no everyone dates it will be null
        availability.lockAt = foundOverride ? foundOverride.lockAt : props.assignment.lockAt
        availability.delayedPostAt = foundOverride
          ? foundOverride.unlockAt
          : props.assignment.unlockAt
      })
    } else {
      // If is not graded the availabilities share the same dates
      selectedAvailabilities.forEach(availability => {
        availability.lockAt = props.lockAt
        availability.delayedPostAt = props.delayedPostAt
      })
    }
    return selectedAvailabilities
  }, [
    props.assignment,
    props.courseSections,
    props.delayedPostAt,
    props.groupSet,
    props.lockAt,
    props.totalUserCount,
  ])

  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({tablet: true, desktop: true})}
      props={{
        tablet: {
          textSize: 'x-small',
          margin: '0 0 0 xxx-small',
        },
        desktop: {
          textSize: 'small',
          margin: '0 0 0 xx-small',
        },
      }}
      render={responsiveProps => {
        return (
          <Flex>
            <Flex.Item margin="0 xxx-small 0 0">
              {prefixText && <Text size={responsiveProps.textSize}>{prefixText}</Text>}
            </Flex.Item>
            <Flex.Item>
              {availabilities.length === 1 ? (
                <AssignmentAvailabilityWindow
                  availabilityWindowName={availabilities[0].name}
                  availableDate={props.delayedPostAt}
                  untilDate={props.lockAt}
                  anonymousState={props.anonymousState}
                  showDateWithTime={true}
                />
              ) : (
                <>
                  {prefixText && <Text size={responsiveProps.textSize}>{' | '}</Text>}
                  <Link
                    isWithinText={false}
                    as="button"
                    onClick={() => {
                      setAvailabilityTrayOpen(true)
                    }}
                    data-testid="view-availability-button"
                    margin={responsiveProps.margin}
                  >
                    <Text weight="bold" size={responsiveProps.textSize}>
                      {I18n.t('View Availability')}
                    </Text>
                  </Link>
                  <TrayDisplayer
                    setTrayOpen={setAvailabilityTrayOpen}
                    trayTitle="Availability"
                    isTrayOpen={availabilityTrayOpen}
                    trayComponent={<DiscussionAvailabilityTray availabilities={availabilities} />}
                  />
                </>
              )}
            </Flex.Item>
          </Flex>
        )
      }}
    />
  )
}

DiscussionAvailabilityContainer.propTypes = {
  courseSections: PropTypes.array,
  anonymousState: PropTypes.string,
  lockAt: PropTypes.string,
  delayedPostAt: PropTypes.string,
  totalUserCount: PropTypes.number,
  groupSet: PropTypes.object,
  assignment: PropTypes.object,
}
