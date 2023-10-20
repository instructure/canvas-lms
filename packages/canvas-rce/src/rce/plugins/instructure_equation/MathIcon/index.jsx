/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {string} from 'prop-types'
import {IconWarningLine} from '@instructure/ui-icons'
import {SVGIcon} from '@instructure/ui-svg-images'
import svgs from './svgs'

export default function MathIcon({command}) {
  if (command in svgs) {
    return <SVGIcon src={svgs[command]} data-testid="math-symbol-icon" />
  } else {
    return <IconWarningLine data-testid="warning-icon" />
  }
}

MathIcon.propTypes = {
  command: string.isRequired,
}
