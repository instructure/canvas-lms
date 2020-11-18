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
import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {Flex} from '@instructure/ui-flex'

const t = str => str

export const SubjectInput = ({value, onChange, onBlur, onFocus}) => {
  return (
    <Flex width="100%">
      <Flex.Item padding="xx-small">
        <PresentationContent>
          <Text size="small">{t('Subject')}</Text>
        </PresentationContent>
      </Flex.Item>
      <Flex.Item shouldGrow padding="xx-small">
        <TextInput
          renderLabel={<ScreenReaderContent>{t('Subject')}</ScreenReaderContent>}
          placeholder={t('No Subject')}
          value={value}
          width="100%"
          onChange={onChange}
          onBlur={onBlur}
          onFocus={onFocus}
        />
      </Flex.Item>
    </Flex>
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
  value: PropTypes.string
}

SubjectInput.defaultProps = {
  onBlur: () => {},
  onFocus: () => {},
  value: ''
}
