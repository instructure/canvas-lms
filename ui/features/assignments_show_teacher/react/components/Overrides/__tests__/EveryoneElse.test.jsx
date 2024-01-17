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
import {useScope as useI18nScope} from '@canvas/i18n'
import * as tz from '@canvas/datetime'
import {render} from '@testing-library/react'
import {mockAssignment, mockOverride} from '../../../test-utils'
import EveryoneElse from '../EveryoneElse'

const I18n = useI18nScope('assignments_2')

const aDueAt = '2018-11-27T13:00-0500'
const aUnlockAt = '2018-11-26T13:00-0500'
const aLockAt = '2018-11-28T13:00-0500'
const oDueAt = '2019-11-27T13:00-0500'
const oUnlockAt = '2019-11-26T13:00-0500'
const oLockAt = '2019-11-28T13:00-0500'

it("pulls everyone else's dates from the assignment", () => {
  const override = mockOverride({dueAt: oDueAt, unlockAt: oUnlockAt, lockAt: oLockAt})
  const assignment = mockAssignment({
    dueAt: aDueAt,
    unlockAt: aUnlockAt,
    lockAt: aLockAt,
    assignmentOverrides: {
      nodes: [override],
    },
  })

  const {getByText, getAllByText} = render(
    <EveryoneElse
      assignment={assignment}
      onChangeAssignment={() => {}}
      onValidate={() => true}
      invalidMessage={() => undefined}
    />
  )
  expect(getByText('Everyone else')).toBeInTheDocument()

  const due = `Due: ${tz.format(aDueAt, I18n.t('#date.formats.full'))}`
  expect(getAllByText(due, {exact: false})[0]).toBeInTheDocument()

  const dates = `${tz.format(aUnlockAt, I18n.t('#date.formats.short'))} to ${tz.format(
    aLockAt,
    I18n.t('#date.formats.short')
  )}`
  expect(getAllByText(dates)[0]).toBeInTheDocument()
})
