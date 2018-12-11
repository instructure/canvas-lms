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
import {render} from 'react-testing-library'
import {mockOverride} from '../../../test-utils'
import OverrideDates from '../OverrideDates'

import I18n from 'i18n!assignments_2'
import tz from 'timezone'

it('renders readonly override dates', () => {
  const override = mockOverride()

  const {getByText} = render(
    <OverrideDates dueAt={override.dueAt} unlockAt={override.unlockAt} lockAt={override.lockAt} />
  )

  const due = `${tz.format(override.dueAt, I18n.t('#date.formats.full'))}`
  const available = `${tz.format(override.unlockAt, I18n.t('#date.formats.full'))}`
  const until = `${tz.format(override.lockAt, I18n.t('#date.formats.full'))}`
  expect(getByText('Due:')).toBeInTheDocument()
  expect(getByText(due)).toBeInTheDocument()
  expect(getByText('Available:')).toBeInTheDocument()
  expect(getByText(available)).toBeInTheDocument()
  expect(getByText('Until:')).toBeInTheDocument()
  expect(getByText(until)).toBeInTheDocument()
})
