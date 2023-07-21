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
import {TextInput} from '@instructure/ui-text-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('account_settings_jsx_bundle')

/**
 * @param {Object} props
 * @param {(event: Object, result: {value: string})} props.suffixInputHandler
 * @param {string} props.loginAttributeSuffix
 * @param {{text: string, type: string}[]} props.messages
 * @returns
 */
const LoginAttributeSuffixInput = ({suffixInputHandler, loginAttributeSuffix, messages}) => {
  return (
    <>
      <TextInput
        renderLabel={
          <ScreenReaderContent>{I18n.t('Login Attribute Suffix Input Area')}</ScreenReaderContent>
        }
        type="text"
        placeholder={I18n.t('@example.edu')}
        onChange={suffixInputHandler}
        defaultValue={loginAttributeSuffix}
        messages={messages}
      />
    </>
  )
}

LoginAttributeSuffixInput.propTypes = {
  suffixInputHandler: PropTypes.func,
  loginAttributeSuffix: PropTypes.string,
  messages: PropTypes.arrayOf(
    PropTypes.shape({
      text: PropTypes.string,
      type: PropTypes.oneOf(['error', 'hint', 'success', 'screenreader-only']),
    })
  ),
}

export default LoginAttributeSuffixInput
