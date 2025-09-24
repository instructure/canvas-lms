/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {string, func, bool} from 'prop-types'
import {TextInput} from '@instructure/ui-text-input'
import formatMessage from '../../../../format-message'

export default function VideoUrlPanel({fileUrl, setFileUrl, urlHasError}) {
  const handleChange = (_e, val) => {
    setFileUrl(val)
  }

  const getErrorMessage = () => {
    if (!urlHasError) return []
    return [
      {
        text: formatMessage('Please enter a valid video URL from a supported platform.'),
        type: 'newError',
      },
    ]
  }

  return (
    <>
      <TextInput
        name="video-url"
        renderLabel={formatMessage('YouTube embed URL')}
        type="text"
        value={fileUrl}
        onChange={handleChange}
        messages={getErrorMessage()}
      />
    </>
  )
}

VideoUrlPanel.propTypes = {
  fileUrl: string.isRequired,
  setFileUrl: func.isRequired,
  urlHasError: bool,
}
