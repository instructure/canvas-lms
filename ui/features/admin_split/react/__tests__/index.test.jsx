/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import $ from 'jquery'
import AdminSplit from '../index'

function renderAdminSplit() {
  return render(
    <AdminSplit
      user={{id: '1', display_name: 'test user', html_url: 'http://example.com/users/1'}}
      splitUrl="http://example.com/api/v1/users/1/split"
      splitUsers={[
        {id: '2', display_name: 'split1', html_url: 'http://example.com/users/2'},
        {id: '3', display_name: 'split2', html_url: 'http://example.com/users/3'},
      ]}
    />
  )
}

describe('admin split ui', () => {
  it('displays split information', () => {
    const {getByText} = renderAdminSplit()
    expect(getByText(/test user/)).toBeInTheDocument()
    expect(getByText(/split1/)).toBeInTheDocument()
    expect(getByText(/split2/)).toBeInTheDocument()
  })

  it('makes the split api call', () => {
    const spy = jest.spyOn($, 'ajaxJSON').mockImplementation(() => {
      Promise.resolve([])
    })
    const {getByText} = renderAdminSplit()
    fireEvent.click(getByText('Split'))
    expect(spy).toHaveBeenCalledWith(
      'http://example.com/api/v1/users/1/split',
      'POST',
      {},
      expect.any(Function),
      expect.any(Function)
    )
  })
})
