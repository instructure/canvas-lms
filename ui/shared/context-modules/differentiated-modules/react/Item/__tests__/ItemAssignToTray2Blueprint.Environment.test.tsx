/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {cleanup} from '@testing-library/react'
import {
  renderComponent,
  server,
  setupBaseMocks,
  setupEnv,
  setupFlashHolder,
} from './ItemAssignToTrayTestUtils'

describe('ItemAssignToTray - Blueprint Environment Configuration', () => {
  const originalLocation = window.location

  beforeAll(() => {
    server.listen()
    setupFlashHolder()
  })

  afterAll(() => server.close())

  beforeEach(() => {
    setupEnv()
    setupBaseMocks()
    vi.resetAllMocks()
  })

  afterEach(() => {
    window.location = originalLocation
    server.resetHandlers()
    cleanup()
  })

  it('shows blueprint locking info when ENV contains master_course_restrictions', async () => {
    ENV.MASTER_COURSE_DATA = {
      is_master_course_child_content: true,
      restricted_by_master_course: true,
      master_course_restrictions: {
        availability_dates: true,
        content: true,
        due_dates: false,
        points: false,
      },
    }

    const {getAllByText} = renderComponent({
      itemType: 'quiz',
      iconType: 'quiz',
      defaultCards: [],
    })

    expect(
      getAllByText((_, e) => e?.textContent === 'Locked: Availability Dates')[0],
    ).toBeInTheDocument()
  })

  it('does not show banner if in a blueprint source course', async () => {
    ENV.MASTER_COURSE_DATA = {
      is_master_course_master_content: true,
      restricted_by_master_course: true,
      master_course_restrictions: {
        availability_dates: true,
        content: true,
        due_dates: false,
        points: false,
      },
    }

    const {queryByText} = renderComponent({
      itemType: 'quiz',
      iconType: 'quiz',
      defaultCards: [],
    })

    expect(queryByText('Locked:')).not.toBeInTheDocument()
  })
})
