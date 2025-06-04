/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import $ from 'jquery'
import React from 'react'
import {render, act} from '@testing-library/react'
import UsageRightsSelectBox from '../UsageRightsSelectBox'

const ok = x => expect(x).toBeTruthy()
const equal = (x, y) => expect(x).toEqual(y)

describe('UsageRightsSelectBox', () => {
  const licenseData = [
    {
      id: 'cc_some_option',
      name: 'CreativeCommonsOption',
    },
  ]

  beforeEach(() => {
    jest.spyOn($, 'get').mockImplementation((url, callback) => {
      if (callback) {
        callback(licenseData)
      }
      return Promise.resolve(licenseData)
    })
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  test('shows alert message if nothing is chosen and component is setup for a message', () => {
    const {container} = render(<UsageRightsSelectBox showMessage={true} />)
    const alertElement = container.querySelector('.alert')
    ok(
      alertElement &&
        alertElement.textContent.includes(
          "If you do not select usage rights now, this file will be unpublished after it's uploaded.",
        ),
      'message is being shown',
    )
  })

  test('fetches license options when component mounts', async () => {
    const ref = React.createRef()
    await act(async () => {
      render(<UsageRightsSelectBox showMessage={false} ref={ref} />)
    })

    // Wait for next tick to allow state updates
    await act(async () => {
      await new Promise(resolve => setTimeout(resolve, 0))
    })

    equal(ref.current.state.licenseOptions[0].id, 'cc_some_option', 'sets data just fine')
  })

  test('inserts copyright into textbox when passed in', () => {
    const copyright = 'all dogs go to taco bell'
    const {container} = render(<UsageRightsSelectBox copyright={copyright} />)
    const copyrightInput = container.querySelector('#copyrightHolder')
    equal(copyrightInput.defaultValue, copyright)
  })

  test('shows creative commons options when set up', async () => {
    const props = {
      copyright: 'loony',
      use_justification: 'creative_commons',
      cc_value: 'cc_some_option',
    }
    const ref = React.createRef()
    await act(async () => {
      render(<UsageRightsSelectBox {...props} ref={ref} />)
    })

    // Wait for next tick to allow state updates
    await act(async () => {
      await new Promise(resolve => setTimeout(resolve, 0))
    })

    equal(ref.current.creativeCommons.value, 'cc_some_option', 'shows creative commons option')
  })

  $('div.error_box').remove()
})
