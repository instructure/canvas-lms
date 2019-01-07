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
import OverrideSummary from '../OverrideSummary'

it('renders an OverrideSummary', () => {
  const dueAt = '2018-11-27T13:00-0500'
  const unlockAt = '2018-11-26T13:00-0500'
  const lockAt = '2018-11-28T13:00-0500'
  const override = mockOverride({
    title: 'Section A',
    dueAt,
    unlockAt,
    lockAt,
    submissionTypes: ['online_upload', 'online_url']
  })
  const {getByText} = render(<OverrideSummary override={override} />)
  expect(getByText('Section A')).toBeInTheDocument()

  const submission_types = 'File & Url'
  const due = `Due: ${tz.format(dueAt, I18n.t('#date.formats.full'))}`
  const elem = getByText(/^File/)
  expect(elem.textContent).toContain(`${submission_types} | ${due}`)

  const unlock = `${tz.format(unlockAt, I18n.t('#date.formats.short'))}`
  const lock = `to ${tz.format(lockAt, I18n.t('#date.formats.full'))}`
  expect(getByText(unlock)).toBeInTheDocument()
  expect(getByText(lock)).toBeInTheDocument()
})

it('renders an override with no lockAt', () => {
  const dueAt = '2018-11-27T13:00-0500'
  const unlockAt = '2018-11-26T13:00-0500'
  const lockAt = null
  const override = mockOverride({
    title: 'Section A',
    dueAt,
    unlockAt,
    lockAt,
    submissionTypes: []
  })
  const {getByText} = render(<OverrideSummary override={override} />)
  const unlock = `Available after ${tz.format(unlockAt, I18n.t('#date.formats.full'))}`
  expect(getByText(unlock)).toBeInTheDocument()
})

it('renders an override with no unlockAt', () => {
  const dueAt = '2018-11-27T13:00-0500'
  const unlockAt = null
  const lockAt = '2018-11-28T13:00-0500'
  const override = mockOverride({
    title: 'Section A',
    dueAt,
    unlockAt,
    lockAt,
    submissionTypes: []
  })
  const {getByText} = render(<OverrideSummary override={override} />)
  const lock = `Available until ${tz.format(lockAt, I18n.t('#date.formats.full'))}`
  expect(getByText(lock)).toBeInTheDocument()
})
