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

import {responsiveQuerySizes} from '../../utils/index'
import {CondensedButton} from '@instructure/ui-buttons'
import PropTypes from 'prop-types'
import React, {useState} from 'react'

import {Text} from '@instructure/ui-text'
import {Responsive} from '@instructure/ui-responsive'
import {DiscussionAvailabilityTray} from '../DiscussionAvailabilityTray/DiscussionAvailabilityTray'
import {TrayDisplayer} from '../TrayDisplayer/TrayDisplayer'

export function DiscussionAvailabilityContainer({...props}) {
  const [availabilityTrayOpen, setAvailabilityTrayOpen] = useState(false)
  const prefixText =
    props.anonymousState === 'full_anonymity'
      ? I18n.t('Anonymous Discussion | ')
      : props.anonymousState === 'partial_anonymity'
      ? I18n.t('Partially Anonymous Discussion | ')
      : null
  let availabilities = []
  if (!props.groupSet) {
    availabilities = props.courseSections.length
      ? props.courseSections
      : [{userCount: props.totalUserCount, name: I18n.t('All Sections'), id: '1'}]
  } else if (props.groupSet.currentGroup) {
    availabilities = [props.groupSet.currentGroup]
  } else if (props.groupSet?.groupsConnection?.nodes) {
    availabilities = props.groupSet.groupsConnection.nodes
  } else {
    availabilities = [{userCount: props.totalUserCount, name: props.groupSet.name, id: '1'}]
  }

  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({tablet: true, desktop: true})}
      props={{
        tablet: {
          textSize: 'x-small',
          margin: '0 0 0 xxx-small'
        },
        desktop: {
          textSize: 'small',
          margin: '0 0 0 xx-small'
        }
      }}
      render={responsiveProps => (
        <>
          {!!prefixText && <Text size={responsiveProps.textSize}>{prefixText}</Text>}
          <CondensedButton
            onClick={() => {
              setAvailabilityTrayOpen(true)
            }}
            data-testid="view-availability-button"
            margin={responsiveProps.margin}
          >
            <Text weight="bold" size={responsiveProps.textSize}>
              {I18n.t('View Availability')}
            </Text>
          </CondensedButton>
          <TrayDisplayer
            setTrayOpen={setAvailabilityTrayOpen}
            trayTitle="Availability"
            isTrayOpen={availabilityTrayOpen}
            trayComponent={
              <DiscussionAvailabilityTray
                lockAt={props.lockAt}
                delayedPostAt={props.delayedPostAt}
                availabilities={availabilities}
              />
            }
          />
        </>
      )}
    />
  )
}

DiscussionAvailabilityContainer.propTypes = {
  courseSections: PropTypes.array,
  anonymousState: PropTypes.string,
  lockAt: PropTypes.string,
  delayedPostAt: PropTypes.string,
  totalUserCount: PropTypes.number,
  groupSet: PropTypes.object
}
