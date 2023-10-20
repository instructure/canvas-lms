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

import React, {useState, useCallback, useRef} from 'react'
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import ConferenceButton from './ConferenceButton'
import AddLtiConferenceDialog from './AddLtiConferenceDialog'
import webConferenceType from '../proptypes/webConferenceType'

const I18n = useI18nScope('conferences')

const AddConference = ({
  context,
  currentConferenceType,
  conferenceTypes,
  setConference,
  inputRef,
  disabled,
}) => {
  const localInputRef = useRef(null)
  const [isRetrievingLTI, setRetrievingLTI] = useState(false)
  const [selectedType, setSelectedType] = useState(null)

  const createPluginConference = type => {
    setConference({
      conference_type: type.type,
      title: I18n.t('%{name} Conference', {name: type.name}),
      description: '',
    })
  }

  const onLtiContent = useCallback(
    ltiContent => {
      setRetrievingLTI(false)
      const {title, text: description, ...ltiSettings} = ltiContent
      ltiSettings.tool_id = selectedType?.lti_settings?.tool_id

      // A deep linking response may contain settings for launching the LTI Tool
      //   ltiContent?.iframe?.src
      //   ltiContent?.iframe?.width
      //   ltiContent?.iframe?.height

      // the conference_selection placement launches the LTI tool in a new tab, so the only useful attribute in the
      // response is the src
      if (ltiContent?.iframe?.src) {
        ltiSettings.url = ltiContent?.iframe?.src
      }

      // don't set Conference with iframe Object in ltiSettings, it is not used
      if (ltiSettings.iframe) {
        delete ltiSettings.iframe
      }

      setConference({
        conference_type: 'LtiConference',
        title: title || I18n.t('%{name} Conference', {name: selectedType.name}),
        description: description || '',
        lti_settings: ltiSettings,
      })
    },
    [selectedType, setConference]
  )

  const onLtiClose = () => {
    setRetrievingLTI(false)
    setTimeout(() => localInputRef.current?.focus(), 0)
  }

  const onSelect = type => {
    setSelectedType(type)
    if (type.type !== 'LtiConference') {
      createPluginConference(type)
    } else {
      setRetrievingLTI(true)
    }
  }

  return (
    <View as="div" display="block" padding="0 0 x-small">
      {isRetrievingLTI ? (
        <Spinner margin="x-small" renderTitle={I18n.t('Creating conference')} size="x-small" />
      ) : (
        <ConferenceButton
          inputRef={el => {
            if (inputRef) {
              inputRef(el)
            }
            localInputRef.current = el
          }}
          conferenceTypes={conferenceTypes}
          currentConferenceType={currentConferenceType}
          onSelect={onSelect}
          disabled={disabled}
        />
      )}
      {isRetrievingLTI && (
        <AddLtiConferenceDialog
          context={context}
          conferenceType={selectedType}
          isOpen={true}
          onRequestClose={onLtiClose}
          onContent={onLtiContent}
        />
      )}
    </View>
  )
}

AddConference.propTypes = {
  context: PropTypes.string.isRequired,
  conferenceTypes: PropTypes.arrayOf(webConferenceType).isRequired,
  currentConferenceType: webConferenceType,
  setConference: PropTypes.func.isRequired,
  inputRef: PropTypes.func,
  disabled: PropTypes.bool,
}

AddConference.defaultProps = {
  currentConferenceType: null,
  inputRef: null,
  disabled: false,
}

export default AddConference
