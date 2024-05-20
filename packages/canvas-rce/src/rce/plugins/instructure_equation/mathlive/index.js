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

const mathliveCss = require('mathlive/dist/mathlive-fonts.css')

const cssRules = `.ML__popover {
  /* Override this so it shows up on top of dialogs */
  z-index: 20000 !important;
}`

const style = document.createElement('style')
style.appendChild(document.createTextNode(mathliveCss))
style.appendChild(document.createTextNode(cssRules))
document.head.appendChild(style)

export * from 'mathlive'
