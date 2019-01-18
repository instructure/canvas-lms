/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import I18n from 'i18n!assignments_2'
import tz from 'timezone'
import {render} from 'react-testing-library'
import {mockOverride} from '../../../test-utils'
import Override from '../Override'

it('renders an override', () => {
  const override = mockOverride()

  const {getByText} = render(<Override override={override} />)

  // this is really testing the OverrideSummary, but short of shallow rendering
  // to see that's what's happening, I'm at a loss as to what to do
  expect(getByText('Section A')).toBeInTheDocument()

  const due = `Due: ${tz.format(override.dueAt, I18n.t('#date.formats.full'))}`
  expect(getByText(due, {exact: false})).toBeInTheDocument()

  const unlock = `${tz.format(override.unlockAt, I18n.t('#date.formats.short'))}`
  const lock = `to ${tz.format(override.lockAt, I18n.t('#date.formats.full'))}`
  expect(getByText(unlock)).toBeInTheDocument()
  expect(getByText(lock)).toBeInTheDocument()
})
