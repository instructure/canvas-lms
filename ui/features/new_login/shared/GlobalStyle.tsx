/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {Global, css} from '@instructure/emotion'
import React from 'react'

// https://emotion.sh/docs/@emotion/css#global-styles
const GlobalStyle = () => (
  <Global
    styles={css`
      html,
      body {
        overflow-x: hidden;
      }
      html {
        height: 100%;
      }
      body {
        min-height: 100%;
        margin: 0;
      }
    `}
  />
)

export default GlobalStyle
