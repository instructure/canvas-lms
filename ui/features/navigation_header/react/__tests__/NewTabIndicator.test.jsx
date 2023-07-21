// Copyright (C) 2022 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import React from 'react'
import {render} from '@testing-library/react'

import NewTabIndicator from '../NewTabIndicator'

describe('NewTabIndicator', () => {
  beforeEach(() => {
    ENV.current_user_id = 12
    ENV.current_user_visited_tabs = null
  })

  it("renders the pill when the user hasn't seen the feature", () => {
    const {getByText} = render(<NewTabIndicator tabName="account_calendars" />)
    expect(getByText('New Tab')).toBeInTheDocument()
    expect(getByText('New')).toBeInTheDocument()
  })

  it("doesn't render the pill if the user has already seen the feature", () => {
    ENV.current_user_visited_tabs = ['account_calendars', 'other_stuff']
    const {queryByText} = render(<NewTabIndicator tabName="account_calendars" />)
    expect(queryByText('New Tab')).not.toBeInTheDocument()
    expect(queryByText('New')).not.toBeInTheDocument()
  })

  it("doesn't render the pill if there's no current user", () => {
    ENV.current_user_id = null
    const {queryByText} = render(<NewTabIndicator tabName="account_calendars" />)
    expect(queryByText('New Tab')).not.toBeInTheDocument()
    expect(queryByText('New')).not.toBeInTheDocument()
  })
})
