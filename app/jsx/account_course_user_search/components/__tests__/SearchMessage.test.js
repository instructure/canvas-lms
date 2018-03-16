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
import {mount} from 'enzyme'
import SearchMessage from '../SearchMessage'

describe('Pagination Handling', () => {
  it('shows the loading spinner on the page that is becoming current', () => {
    const props = {
      collection: {
        data: [1,2,3],
        links: {
          current: {
            url: 'abc',
            page: '5'
          },
          last: {
            url: 'abc10',
            page: '10'
          }
        }
      },
      setPage: jest.fn(),
      noneFoundMessage: 'None Found!'
    }
    const wrapper = mount(<SearchMessage {...props} />);
    wrapper.setProps({}) // Make sure it triggers componentWillReceiveProps
    wrapper.instance().handleSetPage(6)
    const buttons = wrapper.find('PaginationButton').map(x => x.text())
    expect(buttons).toEqual(['1', '5', 'Loading...', '7', '8', '9', '10'])
  });
})

