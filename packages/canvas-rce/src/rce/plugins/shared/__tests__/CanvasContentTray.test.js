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
import {render} from 'react-testing-library'
import CanvasContentTray from '../CanvasContentTray'

it.each([
  ['links', 'Course Links'],
  ['images', 'Course Images'],
  ['media', 'Course Media'],
  ['documents', 'Course Documents']
])('initialContentType prop as %s labels the tray %s', (contentValue, trayAriaLabel) => {
  const {getByLabelText} = render(
    <CanvasContentTray isOpen initialContentType={contentValue} handleClose={() => {}} />
  )
  expect(getByLabelText(trayAriaLabel)).toBeVisible()
})
