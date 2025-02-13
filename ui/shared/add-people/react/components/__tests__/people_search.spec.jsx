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
import {render, screen} from '@testing-library/react'

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
  const textareaMatchers = {
    email: new RegExp('enter the email addresses', 'i'),
    sis_user_id: new RegExp('enter the sis ids', 'i'),
    login_id: new RegExp('enter the login ids', 'i'),
  }

  test('displays Email Address as default label', () => {
    render(<PeopleSearch {...props} />)

    const textarea = screen.getByText(textareaMatchers.email)
    expect(textarea).toBeInTheDocument()
  })

  test('displays proper label for sis searchType', () => {
    render(<PeopleSearch {...props} searchType="sis_user_id" />)

    const textarea = screen.getByText(textareaMatchers.sis_user_id)
    expect(textarea).toBeInTheDocument()
  })

  test('displays proper label for unique_id searchType', () => {
    render(<PeopleSearch {...props} searchType="unique_id" />)

    const textarea = screen.getByText(textareaMatchers.login_id)
    expect(textarea).toBeInTheDocument()
  })

  test('displays role and section', () => {
    render(<PeopleSearch {...props} />)

    expect(screen.getByTestId('people-search-role-section-container')).toBeInTheDocument()
    expect(screen.getByText('Role')).toBeInTheDocument()
    expect(screen.getByText('Section')).toBeInTheDocument()
  })

  test.each([
    {name: 'Email Addresses', searchType: 'cc_path'},
    {name: 'SIS ID', searchType: 'sis_user_id'},
    {name: 'Login ID', searchType: 'unique_id'},
  ])(
    `it should show an error when the "Next" button is clicked and $name field is empty`,
    async ({searchType}) => {
      const errorMessageText = {text: 'This field is required.', type: 'newError'}
      render(
        <PeopleSearch {...props} searchType={searchType} searchInputError={errorMessageText} />,
      )

      const errorMessage = screen.getByText(errorMessageText.text)
      expect(errorMessage).toBeInTheDocument()
    },
  )
})
