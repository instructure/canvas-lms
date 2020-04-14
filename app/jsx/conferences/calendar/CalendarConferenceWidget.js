/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {View} from '@instructure/ui-view'
import AddConference from './AddConference'
import Conference from './Conference'
import getConferenceType from '../utils/getConferenceType'

const CalendarConferenceWidget = ({context, conference, conferenceTypes, setConference}) => {
  const currentConferenceType = conference && getConferenceType(conferenceTypes, conference)
  return (
    <View as="div" padding="0 0 x-small">
      {(!conference || conferenceTypes.length > 1) && (
        <AddConference
          context={context}
          currentConferenceType={currentConferenceType}
          conferenceTypes={conferenceTypes}
          setConference={setConference}
        />
      )}
      {conference && (
        <View
          as="div"
          background="secondary"
          borderWidth="small"
          borderRadius="medium"
          padding="xxx-small x-small"
        >
          <Conference
            conference={conference}
            conferenceType={currentConferenceType}
            removeConference={() => setConference(null)}
          />
        </View>
      )}
    </View>
  )
}

export default CalendarConferenceWidget
