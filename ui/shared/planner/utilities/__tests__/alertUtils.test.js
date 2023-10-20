/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import * as AlertUtils from '../alertUtils'

describe('alert', () => {
  const fakeVisualSuccess = jest.fn()
  const fakeVisualError = jest.fn()

  beforeAll(() => {
    AlertUtils.initialize({
      visualSuccessCallback: fakeVisualSuccess,
      visualErrorCallback: fakeVisualError,
    })
  })

  it('calls the visualSuccessCallback when isError is false (by default)', () => {
    AlertUtils.alert('Hey')
    expect(fakeVisualSuccess).toHaveBeenCalledWith('Hey')
  })

  it('call the visualErrorCallback when isError is true', () => {
    AlertUtils.alert('Hey You', true)
    expect(fakeVisualError).toHaveBeenCalledWith('Hey You')
  })
})

describe('srAlert', () => {
  it('calls srAlertCallback', () => {
    const fakeSRAlert = jest.fn()
    AlertUtils.initialize({
      srAlertCallback: fakeSRAlert,
    })
    AlertUtils.srAlert('This is something else :)')
    expect(fakeSRAlert).toHaveBeenCalledWith('This is something else :)')
  })
})
