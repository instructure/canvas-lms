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

import {StyleSheet} from 'aphrodite'

const cssRules = `#MathJax_MenuFrame {
  z-index: 10000 !important;
}`

// Applying z-index for MathJax menu inside config shows the element but doesn't user interact with it.
// Manually adding z-index as head style
const style = document.createElement('style')
style.appendChild(document.createTextNode(cssRules))
document.head.appendChild(style)

export default StyleSheet.create({
  mathfieldContainer: {
    all: 'initial',
  },

  mathFieldContainer: {
    width: '100%',
    position: 'relative',
  },

  latexToggle: {
    marginTop: '0.5em',
  },
})
