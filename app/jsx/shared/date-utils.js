/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import moment from 'moment';
import React from 'react'
import 'jquery.instructure_date_and_time'

import View from '@instructure/ui-layout/lib/components/View'
import Text from '@instructure/ui-elements/lib/components/Text'
import IconTimer from '@instructure/ui-icons/lib/Line/IconTimer'

/*
 * returns whether or not the current date is passed the date
 */
export function isPassedDelayedPostAt({ checkDate, delayedDate }) {
  const checkMomentDate = checkDate ? moment(checkDate) : moment()
  const checkDelayedDate = moment(delayedDate)
  return checkMomentDate.isAfter(checkDelayedDate)
}

export function makeTimestamp({ delayed_post_at, posted_at }, delayedLabel, postedOnLabel) {
  return (delayed_post_at
    && !isPassedDelayedPostAt({ checkDate: null, delayedDate: delayed_post_at}))
    ? {
        title: (
          <span>
            <View margin="0 x-small">
              <Text color="secondary">
                <IconTimer />
              </Text>
            </View>
            {delayedLabel}
          </span>
        ),
        date: delayed_post_at
      }
    : {title: postedOnLabel, date: posted_at}
}
