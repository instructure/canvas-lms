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

import React, {useState} from 'react'
import I18n from 'i18n!copy_to_clipboard'
import PropTypes from 'prop-types'

import {TextInput} from '@instructure/ui-text-input'
import {Button} from '@instructure/ui-buttons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

const CopyToClipboard = props => {
  const [inputElement, setInputElement] = useState()

  // Object containing props intended for the TextInput component
  const textInputProps = Object.fromEntries(
    Object.entries(props).filter(([k]) => !CopyToClipboard.propTypes[k])
  )

  const copyToClipboard = () => {
    inputElement.select()
    document.execCommand('copy')
  }

  return (
    <TextInput
      {...textInputProps}
      renderAfterInput={
        <Button onClick={copyToClipboard} size="small">
          {props.buttonText}
          <ScreenReaderContent>
            {I18n.t('Copy the video URL')}
          </ScreenReaderContent>
        </Button>
      }
      inputRef={ref => setInputElement(ref)}
    />
  )
}

CopyToClipboard.propTypes = {
  buttonText: PropTypes.string
}

CopyToClipboard.defaultProps = {
  buttonText: I18n.t('Copy')
}

export default CopyToClipboard
