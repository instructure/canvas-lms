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

import React, {useState, useCallback} from 'react'
import PropTypes from 'prop-types'
import I18n from 'i18n!conferences'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import ConferenceButton from './ConferenceButton'
import AddLtiConferenceDialog from './AddLtiConferenceDialog'
import createConference from '../../utils/createConference'
import {showFlashError} from 'jsx/shared/FlashAlert'
import webConferenceType from 'jsx/shared/proptypes/webConferenceType'

const AddConference = ({context, currentConferenceType, conferenceTypes, setConference}) => {
  const [isCreating, setIsCreating] = useState(false)
  const [isRetrievingLTI, setRetrievingLTI] = useState(false)
  const [selectedType, setSelectedType] = useState(null)

  const createPluginConference = async type => {
    setIsCreating(true)
    try {
      const json = await createConference(context, type)
      setConference(json)
    } catch (err) {
      showFlashError(I18n.t('An error occurred creating the  conference'))()
    }
    setIsCreating(false)
  }

  const onLtiContent = useCallback(
    ltiContent => {
      setRetrievingLTI(false)
      const {title, text: description, ...ltiSettings} = ltiContent
      ltiSettings.tool_id = selectedType?.lti_settings?.tool_id
      setConference({
        conference_type: 'LtiConference',
        title: title || I18n.t('%{name} Conference', {name: selectedType.name}),
        description: description || '',
        lti_settings: ltiSettings
      })
    },
    [selectedType, setConference]
  )

  const onLtiClose = () => {
    setRetrievingLTI(false)
  }

  const onSelect = async type => {
    setSelectedType(type)
    if (type.type !== 'LtiConference') {
      createPluginConference(type)
    } else {
      setRetrievingLTI(true)
    }
  }

  return (
    <View as="div" display="block" padding="0 0 x-small">
      {isCreating || isRetrievingLTI ? (
        <Spinner margin="x-small" renderTitle={I18n.t('Creating conference')} size="x-small" />
      ) : (
        <ConferenceButton
          conferenceTypes={conferenceTypes}
          currentConferenceType={currentConferenceType}
          onSelect={onSelect}
        />
      )}
      {isRetrievingLTI && (
        <AddLtiConferenceDialog
          context={context}
          conferenceType={selectedType}
          isOpen
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
  setConference: PropTypes.func.isRequired
}

export default AddConference
