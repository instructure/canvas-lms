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

import React from 'react'
import PropTypes from 'prop-types'
import moment from 'moment-timezone'

import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'

import * as tz from '@canvas/datetime'
import ImportantDateItem, {ImportantDateItemShape} from './ImportantDateItem'

const ImportantDateSection = ({date, items, timeZone}) => {
  const isSameYear = moment(date).isSame(moment().tz(timeZone), 'year')
  return (
    <View as="div" margin="medium 0 x-small">
      <Heading as="h3" level="h5">
        {tz.format(
          date,
          `date.formats.${isSameYear ? 'long_with_weekday' : 'medium_with_weekday'}`
        )}
      </Heading>
      {items.map(item => (
        <ImportantDateItem key={item.id} {...item} />
      ))}
    </View>
  )
}

ImportantDateSection.propTypes = {
  date: PropTypes.string.isRequired,
  items: PropTypes.arrayOf(PropTypes.shape(ImportantDateItemShape)).isRequired,
  timeZone: PropTypes.string.isRequired,
}

export default ImportantDateSection
