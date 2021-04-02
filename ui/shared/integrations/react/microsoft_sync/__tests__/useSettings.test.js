/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import useSettings from '../useSettings'
import useFetchApi from '@canvas/use-fetch-api-hook'
import {renderHook} from '@testing-library/react-hooks/dom'

jest.mock('@canvas/use-fetch-api-hook')

const courseId = 11
const subject = () => renderHook(() => useSettings(courseId))

afterEach(() => {
  useFetchApi.mockClear()
})

describe('useSettings', () => {
  it('makes a GET request to load the group', () => {
    subject()
    const lastCall = useFetchApi.mock.calls.pop()

    expect(lastCall[0]).toMatchObject({
      path: `/api/v1/courses/${courseId}/microsoft_sync/group`
    })
  })
})
