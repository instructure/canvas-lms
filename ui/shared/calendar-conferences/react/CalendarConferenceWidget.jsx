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

import React, {useRef} from 'react'
import PropTypes from 'prop-types'
import {View} from '@instructure/ui-view'
import {useScope as useI18nScope} from '@canvas/i18n'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import AddConference from './AddConference/index'
import Conference from './Conference'
import getConferenceType from '../getConferenceType'
import webConference from './proptypes/webConference'
import webConferenceType from './proptypes/webConferenceType'

const I18n = useI18nScope('conferences')

const CalendarConferenceWidget = ({
  context,
  conference,
  conferenceTypes,
  setConference,
  disabled,
}) => {
  const addConferenceRef = useRef(null)
  const removeConferenceRef = useRef(null)
  const currentConferenceType = conference && getConferenceType(conferenceTypes, conference)
  const showAddConference =
    setConference && (conferenceTypes.length > 1 || (conferenceTypes.length > 0 && !conference))
  const setConferenceWithAlert = c => {
    setConference(c)
    showFlashAlert({
      message: I18n.t('Conference has been updated: %{title}', {title: c.title}),
      srOnly: true,
    })
    setTimeout(() => removeConferenceRef.current?.focus(), 250)
  }
  const removeConference = () => {
    setConference(null)
    showFlashAlert({message: I18n.t('Conference has been removed'), srOnly: true})
    setTimeout(() => addConferenceRef.current?.focus(), 250)
  }

  return (
    <View as="div" padding="0 0 x-small">
      {showAddConference && (
        <AddConference
          inputRef={el => {
            addConferenceRef.current = el
          }}
          context={context}
          currentConferenceType={currentConferenceType}
          conferenceTypes={conferenceTypes}
          setConference={setConferenceWithAlert}
          disabled={disabled}
        />
      )}
      {conference && (
        <View
          as="div"
          background="secondary"
          borderWidth="small"
          borderRadius="medium"
          padding="xx-small x-small"
        >
          <Conference
            conference={conference}
            conferenceType={currentConferenceType}
            removeConference={removeConference}
            removeButtonRef={el => {
              removeConferenceRef.current = el
            }}
          />
        </View>
      )}
    </View>
  )
}

CalendarConferenceWidget.propTypes = {
  context: PropTypes.string.isRequired,
  conference: webConference,
  conferenceTypes: PropTypes.arrayOf(webConferenceType).isRequired,
  setConference: PropTypes.func,
  disabled: PropTypes.bool,
}

CalendarConferenceWidget.defaultProps = {
  conference: null,
  setConference: null,
  disabled: false,
}

export default CalendarConferenceWidget
