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

import FeatureFlagDialog from 'compiled/views/feature_flags/FeatureFlagDialog'
import {getQueriesForElement, fireEvent} from '@testing-library/dom'

describe('FeatureFlagDialog', () => {
  afterEach(() => {
    // DialogBaseView messes with the body, so reset it each time
    document.getElementsByTagName('html')[0].innerHTML = ''
  })

  const createView = params => {
    const defaultParams = {
      deferred: {resolve: jest.fn(), reject: jest.fn()},
      message: 'message',
      title: 'title',
      hasCancelButton: false
    }

    return new FeatureFlagDialog({
      ...defaultParams,
      ...params
    })
  }

  it('calls onReload when reloadOnConfirm is true', () => {
    const view = createView({reloadOnConfirm: true})
    const stub = jest.spyOn(view, 'onReload').mockImplementation(() => "Don't reload the page")
    view.render()
    view.show()
    // DialogBaseView appends the dialog directly to the body
    const {getByText} = getQueriesForElement(document.body)
    fireEvent.click(getByText('Okay'))

    expect(stub).toHaveBeenCalledTimes(1)
  })

  it('does not call onReload when reloadOnConfirm is false', () => {
    const view = createView({reloadOnConfirm: false})
    const stub = jest.spyOn(view, 'onReload').mockImplementation(() => "Don't reload the page")
    view.render()
    view.show()
    const {getByText} = getQueriesForElement(document.body)
    fireEvent.click(getByText('Okay'))

    expect(stub).not.toHaveBeenCalled()
  })
})
