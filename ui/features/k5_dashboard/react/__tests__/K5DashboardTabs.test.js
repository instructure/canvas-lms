/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {act, render, waitFor} from '@testing-library/react'
import K5Dashboard from '../K5Dashboard'
import {defaultK5DashboardProps as defaultProps} from './mocks'

jest.setTimeout(20000)

describe('K5Dashboard Tabs', () => {
  afterEach(() => {
    window.location.hash = ''
  })

  it('show Homeroom, Schedule, Grades, and Resources options', async () => {
    const {getByText} = render(<K5Dashboard {...defaultProps} />)
    await waitFor(() => {
      ;['Homeroom', 'Schedule', 'Grades', 'Resources'].forEach(label =>
        expect(getByText(label)).toBeInTheDocument()
      )
    })
  })

  it('default to the Homeroom tab', async () => {
    const {findByRole} = render(<K5Dashboard {...defaultProps} />)
    expect(await findByRole('tab', {name: 'Homeroom', selected: true})).toBeInTheDocument()
  })
  describe('store current tab ID to URL', () => {
    afterEach(() => {
      window.location.hash = ''
    })

    it('and start at that tab if it is valid', async () => {
      window.location.hash = '#grades'
      const {findByRole} = render(<K5Dashboard {...defaultProps} />)
      expect(await findByRole('tab', {name: 'Grades', selected: true})).toBeInTheDocument()
    })

    it('and start at the default tab if it is invalid', async () => {
      window.location.hash = 'tab-not-a-real-tab'
      const {findByRole} = render(<K5Dashboard {...defaultProps} />)
      expect(await findByRole('tab', {name: 'Homeroom', selected: true})).toBeInTheDocument()
    })

    it('and update the current tab as tabs are changed', async () => {
      const {findByRole, getByRole, queryByRole} = render(<K5Dashboard {...defaultProps} />)
      const gradesTab = await findByRole('tab', {name: 'Grades'})
      act(() => gradesTab.click())
      expect(await findByRole('tab', {name: 'Grades', selected: true})).toBeInTheDocument()
      act(() => getByRole('tab', {name: 'Resources'}).click())
      expect(await findByRole('tab', {name: 'Resources', selected: true})).toBeInTheDocument()
      expect(queryByRole('tab', {name: 'Grades', selected: true})).not.toBeInTheDocument()
    })
  })
})
