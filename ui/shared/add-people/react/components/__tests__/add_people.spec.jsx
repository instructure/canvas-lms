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

import {render, waitFor, within} from '@testing-library/react'
import React from 'react'
import AddPeople from '../add_people'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'

injectGlobalAlertContainers()

describe('Focus Handling', () => {
  it('sends focus to the modal close button when an api error occurs', () => {
    const props = {
      isOpen: true,
      courseParams: {
        roles: [],
        sections: [],
      },
      apiState: {
        isPending: 0,
      },
      inputParams: {
        nameList: '',
      },
      validateUsers() {},
      enrollUsers() {},
      reset() {},
    }

    const wrapper = render(<AddPeople {...props} />)
    wrapper.rerender(
      <AddPeople
        {...props}
        apiState={{
          error: 'Some random error',
        }}
      />
    )

    expect(within(document.activeElement).queryByText('Cancel')).toBeInTheDocument()
  })

  it('sends focus to the modal close button when people validation issues happen', () => {
    const props = {
      isOpen: true,
      courseParams: {
        roles: [],
        sections: [],
      },
      apiState: {
        isPending: 0,
      },
      inputParams: {
        nameList: '',
        searchType: 'unique_id',
        role: 'student',
        section: '1',
      },
      userValidationResult: {
        missing: {
          'gotta have': 'something missing',
        },
        duplicates: {},
      },
      validateUsers() {},
      enrollUsers() {},
      reset() {},
    }
    const ref = React.createRef()
    render(<AddPeople {...props} ref={ref} />)

    ref.current.setState({
      currentPage: 'peoplevalidationissues',
    })

    waitFor(() => {
      expect(within(document.activeElement).queryByText('Cancel')).toBeInTheDocument()
    })
  })
})
