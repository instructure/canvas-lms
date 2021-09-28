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

import DateHelper from '@canvas/datetime/dateHelper'
import React from 'react'
import {responsiveQuerySizes} from '../../utils/index'

import PropTypes from 'prop-types'
import {Responsive} from '@instructure/ui-responsive'
import {Text} from '@instructure/ui-text'

export function AssignmentAvailabilityWindow({...props}) {
  let availabilityWindow = null

  if (props.availableDate && props.untilDate) {
    availabilityWindow = I18n.t('Available from %{availableDate} until %{untilDate}', {
      availableDate: DateHelper.formatDateForDisplay(props.availableDate, 'short'),
      untilDate: DateHelper.formatDateForDisplay(props.untilDate, 'short')
    })
  } else if (props.availableDate) {
    availabilityWindow = I18n.t('Available from %{availableDate}', {
      availableDate: DateHelper.formatDateForDisplay(props.availableDate, 'short')
    })
  } else if (props.untilDate) {
    availabilityWindow = I18n.t('Available until %{untilDate}', {
      untilDate: DateHelper.formatDateForDisplay(props.untilDate, 'short')
    })
  }

  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({tablet: true, desktop: true})}
      props={{
        tablet: {
          textSize: 'x-small',
          displayText: null
        },
        desktop: {
          textSize: 'small',
          displayText: availabilityWindow
        }
      }}
      render={responsiveProps => {
        return responsiveProps.displayText ? (
          <Text weight="normal" size={responsiveProps.textSize}>
            {responsiveProps.displayText}
          </Text>
        ) : null
      }}
    />
  )
}

AssignmentAvailabilityWindow.prototypes = {
  availableDate: PropTypes.string,
  untilDate: PropTypes.string
}
