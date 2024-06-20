/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import {render, screen} from '@testing-library/react'
import AppDetails from '../AppDetails'

describe('External Apps App Details', () => {
  it('the back to app center link goes to the proper place', () => {
    const fakeStore = {
      findAppByShortName: jest.fn().mockReturnValue({
        short_name: 'someApp',
        config_options: [],
      }),
    }

    render(<AppDetails baseUrl="/someUrl" shortName="someApp" store={fakeStore} />)

    const link = screen.getByRole('link', {name: /back to app center/i}) // Adjust the name to match the text or aria-label used in your link

    expect(new URL(link.href).pathname).toBe('/someUrl')
  })
})
