/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {string, func} from 'prop-types'
import {TextArea} from '@instructure/ui-forms'

export default function EmbedPanel({embedCode, setEmbedCode, label}) {
  return (
    <TextArea
      maxHeight="10rem"
      label={label}
      value={embedCode}
      placeholder={label}
      onChange={e => setEmbedCode(e.target.value)}
    />
  )
}

EmbedPanel.propTypes = {
  embedCode: string.isRequired,
  label: string.isRequired,
  setEmbedCode: func.isRequired
}
