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
// I18n and tz needed to replicate what FriendlyDatetime does in formatting
import {useScope as useI18nScope} from '@canvas/i18n'
import * as tz from '@canvas/datetime'
import {render} from '@testing-library/react'
import {mockOverride} from '../../../test-utils'
import OverrideSummary from '../OverrideSummary'

const I18n = useI18nScope('assignments_2')

describe('OverrideSummary', () => {
  it('renders with unlock and lock dates', () => {
    const dueAt = '2018-11-27T13:00-0500'
    const unlockAt = '2018-11-26T13:00-0500'
    const lockAt = '2018-11-28T13:00-0500'
    const override = mockOverride({
      title: 'Section A',
      dueAt,
      unlockAt,
      lockAt,
      submissionTypes: ['online_upload', 'online_url'],
      allowedAttempts: 1,
    })
    const {getAllByText, getByTestId} = render(<OverrideSummary override={override} />)
    expect(getByTestId('OverrideAssignTo')).toBeInTheDocument()
    expect(getByTestId('OverrideSubmissionTypes')).toBeInTheDocument()

    const due = `Due: ${tz.format(dueAt, I18n.t('#date.formats.full'))}`
    expect(getAllByText(due)[0]).toBeInTheDocument()

    const dates = `${tz.format(unlockAt, I18n.t('#date.formats.short'))} to ${tz.format(
      lockAt,
      I18n.t('#date.formats.short')
    )}`
    expect(getAllByText(dates)[0]).toBeInTheDocument()

    expect(getByTestId('OverrideAttempts-Summary')).toBeInTheDocument()
  })

  it('renders with neither unlock or lock dates', () => {
    const dueAt = '2018-11-27T13:00-0500'
    const unlockAt = null
    const lockAt = null
    const override = mockOverride({
      title: 'Section A',
      dueAt,
      unlockAt,
      lockAt,
      submissionTypes: ['online_upload', 'online_url'],
      allowedAttempts: 1,
    })
    const {getByText} = render(<OverrideSummary override={override} />)

    expect(getByText('Available')).toBeInTheDocument()
  })

  it('renders with only unlock date', () => {
    const dueAt = '2018-11-27T13:00-0500'
    const unlockAt = '2018-11-26T13:00-0500'
    const lockAt = null
    const override = mockOverride({
      title: 'Section A',
      dueAt,
      unlockAt,
      lockAt,
      submissionTypes: ['online_upload', 'online_url'],
      allowedAttempts: 1,
    })
    const {getAllByText} = render(<OverrideSummary override={override} />)

    const unlock = `${tz.format(unlockAt, I18n.t('#date.formats.short'))}`
    expect(getAllByText(`Available after ${unlock}`)[0]).toBeInTheDocument()
  })

  it('renders with only lock date', () => {
    const dueAt = '2018-11-27T13:00-0500'
    const unlockAt = null
    const lockAt = '2018-11-28T13:00-0500'
    const override = mockOverride({
      title: 'Section A',
      dueAt,
      unlockAt,
      lockAt,
      submissionTypes: ['online_upload', 'online_url'],
      allowedAttempts: 1,
    })
    const {getAllByText} = render(<OverrideSummary override={override} />)

    const lock = `${tz.format(lockAt, I18n.t('#date.formats.short'))}`
    expect(getAllByText(`Available until ${lock}`)[0]).toBeInTheDocument()
  })
})
