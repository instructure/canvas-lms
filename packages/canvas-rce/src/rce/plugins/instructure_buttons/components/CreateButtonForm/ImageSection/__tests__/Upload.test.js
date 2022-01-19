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
import {render, waitFor} from '@testing-library/react'
import Upload from '../Upload'
import FakeEditor from '../../../../../shared/__tests__/FakeEditor'
import fetchMock from 'fetch-mock'

jest.mock('../../../../../../../bridge', () => {
  return {
    trayProps: {
      get: editor => ({foo: 'bar'})
    }
  }
})

let props
const subject = overrides => render(<Upload {...props} />)

describe('Upload()', () => {
  beforeEach(() => {
    props = {editor: new FakeEditor()}
    fetchMock.mock('/api/session', '{}')
  })

  afterEach(() => {
    fetchMock.restore()
  })

  it('renders an upload modal', async () => {
    const {getAllByText} = subject(props)
    await waitFor(() => expect(getAllByText('Upload Image').length).toBe(2))
  })
})
