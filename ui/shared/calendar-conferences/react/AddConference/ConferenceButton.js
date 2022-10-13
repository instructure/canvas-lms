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
import PropTypes from 'prop-types'
import {Button} from '@instructure/ui-buttons'
import {Img} from '@instructure/ui-img'
import {Text} from '@instructure/ui-text'
import {PresentationContent} from '@instructure/ui-a11y-content'
import {useScope as useI18nScope} from '@canvas/i18n'
import ConferenceSelect from './ConferenceSelect'
import webConferenceType from '../proptypes/webConferenceType'

const I18n = useI18nScope('conferences')

const ConferenceButton = ({
  conferenceTypes,
  currentConferenceType,
  onSelect,
  inputRef,
  disabled,
}) => {
  if (!conferenceTypes || conferenceTypes.length === 0) {
    return (
      <Text size="small" color="danger">
        {I18n.t('No conferencing options enabled')}
      </Text>
    )
  } else if (conferenceTypes.length === 1) {
    const conferenceType = conferenceTypes[0]
    const icon = conferenceType.lti_settings?.icon_url
    const name = conferenceType.lti_settings?.text || conferenceType.name
    return (
      <Button
        elementRef={inputRef}
        color="primary-inverse"
        size="small"
        onClick={() => onSelect(conferenceType)}
        disabled={disabled}
      >
        {icon && (
          <PresentationContent>
            <Img src={icon} margin="0 x-small 0 0" height="20px" width="20px" />
          </PresentationContent>
        )}
        {name ? I18n.t('Add %{name}', {name}) : I18n.t('Add Conferencing')}
      </Button>
    )
  } else {
    return (
      <ConferenceSelect
        inputRef={inputRef}
        currentConferenceType={currentConferenceType}
        conferenceTypes={conferenceTypes}
        onSelectConferenceType={onSelect}
      />
    )
  }
}

ConferenceButton.propTypes = {
  conferenceTypes: PropTypes.arrayOf(webConferenceType).isRequired,
  currentConferenceType: webConferenceType,
  onSelect: PropTypes.func.isRequired,
  inputRef: PropTypes.func,
}

ConferenceButton.defaultProps = {
  currentConferenceType: null,
  inputRef: null,
}

export default ConferenceButton
