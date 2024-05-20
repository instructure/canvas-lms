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
import PeopleSearch from '../people_search'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'
import {render} from '@testing-library/react'

injectGlobalAlertContainers()

describe('PeopleSearch', () => {
  const props = {
    roles: [
      {id: '0', a: 'teacher'},
      {id: '1', b: 'student'},
    ],
    sections: [
      {id: '0', a: 'secA'},
      {id: '1', b: 'secB'},
    ],
  }

  test('displays Email Address as default label', () => {
    const wrapper = render(<PeopleSearch {...props} />)
    expect(wrapper.queryByText('Email Addresses (required)')).toBeInTheDocument()
  })

  test('displays proper label for sis searchType', () => {
    const wrapper = render(<PeopleSearch {...props} searchType="sis_user_id" />)
    expect(wrapper.queryByText('SIS IDs (required)')).toBeInTheDocument()
  })

  test('displays proper label for unique_id searchType', () => {
    const wrapper = render(<PeopleSearch {...props} searchType="unique_id" />)
    expect(wrapper.queryByText('Login IDs (required)')).toBeInTheDocument()
  })
})
