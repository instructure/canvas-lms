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

import {ComposeInputWrapper} from '../ComposeInputWrapper/ComposeInputWrapper'
import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React from 'react'

import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'

const I18n = useI18nScope('conversations_2')

export const SubjectInput = ({value, onChange, onBlur, onFocus}) => {
  return (
    <ComposeInputWrapper
      title={
        <PresentationContent>
          <Text size="small">{I18n.t('Subject')}</Text>
        </PresentationContent>
      }
      input={
        <TextInput
          data-testid="subject-input"
          renderLabel={<ScreenReaderContent>{I18n.t('Subject')}</ScreenReaderContent>}
          placeholder={I18n.t('Insert Subject')}
          value={value}
          width="100%"
          onChange={onChange}
          onBlur={onBlur}
          onFocus={onFocus}
        />
      }
      shouldGrow={true}
    />
  )
}

SubjectInput.propTypes = {
  /**
   * Callback for Subject Input Change
   */
  onChange: PropTypes.func.isRequired,
  /**
   * Callback for Subject Input blur
   */
  onBlur: PropTypes.func,
  /**
   * Callback for Subject Input Focus
   */
  onFocus: PropTypes.func,
  /**
   * Value prop for Subject Input
   */
  value: PropTypes.string,
}

SubjectInput.defaultProps = {
  onBlur: () => {},
  onFocus: () => {},
  value: '',
}
