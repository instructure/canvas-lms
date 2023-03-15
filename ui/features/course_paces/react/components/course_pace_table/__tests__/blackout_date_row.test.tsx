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
import {render} from '@testing-library/react'
import {renderRow} from '@canvas/util/react/testing/TableHelper'

import {BLACKOUT_DATES} from '../../../__tests__/fixtures'

import BlackoutDateRow from '../blackout_date_row'

const defaultProps = {
  blackoutDate: BLACKOUT_DATES[0],
}

describe('BlackoutDateRow', () => {
  it('renders the blackout date title', () => {
    const {getByText} = render(renderRow(<BlackoutDateRow {...defaultProps} />))
    expect(getByText(defaultProps.blackoutDate.event_title)).toBeInTheDocument()
  })

  it('renders the duration of blackout date', () => {
    const {container} = render(renderRow(<BlackoutDateRow {...defaultProps} />))
    expect(container.querySelectorAll('td')[1].textContent).toEqual('5')
  })

  it('renders the start and end dates', () => {
    const {container} = render(renderRow(<BlackoutDateRow {...defaultProps} />))
    expect(container.querySelectorAll('td')[2].textContent).toEqual(
      'Mon, Mar 21, 2022 - Fri, Mar 25, 2022'
    )
  })

  it('renders just the start date for single day blackouts', () => {
    const props = {blackoutDate: {...defaultProps.blackoutDate}}
    props.blackoutDate.end_date = props.blackoutDate.start_date.clone()
    const {container} = render(renderRow(<BlackoutDateRow {...props} />))
    const cells = container.querySelectorAll('td')
    expect(cells[2].textContent).toEqual('Mon, Mar 21, 2022')
    expect(cells[1].textContent).toEqual('1')
  })

  describe('localized', () => {
    const locale = ENV.LOCALE
    beforeAll(() => {
      ENV.LOCALE = 'en-GB'
    })
    afterAll(() => {
      ENV.LOCALE = locale
    })
    it('localizes the projected dates', () => {
      const {getByText} = render(renderRow(<BlackoutDateRow {...defaultProps} />))
      expect(getByText('Mon, 21 Mar 2022')).toBeInTheDocument()
      expect(getByText('Fri, 25 Mar 2022')).toBeInTheDocument()
    })
  })
})
