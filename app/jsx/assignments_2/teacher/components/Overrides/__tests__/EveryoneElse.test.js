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
import {mockAssignment, mockOverride} from '../../../test-utils'
import EveryoneElse from '../EveryoneElse'

it("pulls everyone's dates from the assignment", () => {
  const dueAt = '2018-11-27T13:00-0500'
  const unlockAt = '2018-11-26T13:00-0500'
  const lockAt = '2018-11-28T13:00-0500'

  const assignment = mockAssignment({
    dueAt,
    unlockAt,
    lockAt
  })

  const {getByText} = render(<EveryoneElse assignment={assignment} />)
  expect(getByText('Everyone')).toBeInTheDocument()

  const due = `Due: ${tz.format(dueAt, I18n.t('#date.formats.full'))}`
  expect(getByText(due, {exact: false})).toBeInTheDocument()

  const unlock = `${tz.format(unlockAt, I18n.t('#date.formats.short'))}`
  const lock = `to ${tz.format(lockAt, I18n.t('#date.formats.full'))}`
  expect(getByText(unlock)).toBeInTheDocument()
  expect(getByText(lock)).toBeInTheDocument()
})

it("pulls everyone else's dates from the assignment", () => {
  const aDueAt = '2018-11-27T13:00-0500'
  const aUnlockAt = '2018-11-26T13:00-0500'
  const aLockAt = '2018-11-28T13:00-0500'
  const oDueAt = '2019-11-27T13:00-0500'
  const oUnlockAt = '2019-11-26T13:00-0500'
  const oLockAt = '2019-11-28T13:00-0500'

  const override = mockOverride({dueAt: oDueAt, unlockAt: oUnlockAt, lockAt: oLockAt})
  const assignment = mockAssignment({
    dueAt: aDueAt,
    unlockAt: aUnlockAt,
    lockAt: aLockAt,
    assignmentOverrides: {
      nodes: [override]
    }
  })

  const {getByText} = render(<EveryoneElse assignment={assignment} />)
  expect(getByText('Everyone else')).toBeInTheDocument()

  const due = `Due: ${tz.format(aDueAt, I18n.t('#date.formats.full'))}`
  expect(getByText(due, {exact: false})).toBeInTheDocument()

  const unlock = `${tz.format(aUnlockAt, I18n.t('#date.formats.short'))}`
  const lock = `to ${tz.format(aLockAt, I18n.t('#date.formats.full'))}`
  expect(getByText(unlock)).toBeInTheDocument()
  expect(getByText(lock)).toBeInTheDocument()
})
