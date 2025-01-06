/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {screen, waitFor} from '@testing-library/react'
import StatusPill from '../index'

describe('StatusPill', () => {
  let container

  beforeEach(() => {
    container = document.createElement('div')
    container.id = 'fixtures'
    document.body.appendChild(container)
  })

  afterEach(() => {
    container.remove()
  })

  const addSpans = (className, count = 3) => {
    return Array.from({length: count}).map(() => {
      const span = document.createElement('span')
      span.className = className
      return container.appendChild(span)
    })
  }

  it('renders missing pills with correct text', async () => {
    addSpans('submission-missing-pill')
    StatusPill.renderPills()
    await waitFor(() => {
      const pills = screen.getAllByText('missing')
      expect(pills).toHaveLength(3)
    })
  })

  it('renders late pills with correct text', async () => {
    addSpans('submission-late-pill')
    StatusPill.renderPills()
    await waitFor(() => {
      const pills = screen.getAllByText('late')
      expect(pills).toHaveLength(3)
    })
  })

  it('renders excused pills with correct text', async () => {
    addSpans('submission-excused-pill')
    StatusPill.renderPills()
    await waitFor(() => {
      const pills = screen.getAllByText('excused')
      expect(pills).toHaveLength(3)
    })
  })

  it('renders extended pills with correct text', async () => {
    addSpans('submission-extended-pill')
    StatusPill.renderPills()
    await waitFor(() => {
      const pills = screen.getAllByText('extended')
      expect(pills).toHaveLength(3)
    })
  })

  it('renders custom grade status pills with correct text', async () => {
    const statuses = [
      {id: '1', name: 'status one'},
      {id: '2', name: 'status two'},
      {id: '3', name: 'status three'},
    ]

    statuses.forEach(status => {
      const span = document.createElement('span')
      span.className = `submission-custom-grade-status-pill-${status.id}`
      container.appendChild(span)
    })

    StatusPill.renderPills(statuses)

    await waitFor(() => {
      statuses.forEach(status => {
        const pills = screen.getAllByText(status.name)
        expect(pills).toHaveLength(1)
      })
    })
  })
})
