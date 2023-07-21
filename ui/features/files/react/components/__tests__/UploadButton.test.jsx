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

import React from 'react'
import {act, render} from '@testing-library/react'
import UploadButton from '../UploadButton'
import UploadQueue from '@canvas/files/react/modules/UploadQueue'

function renderUploadButton(overrides) {
  return render(
    <UploadButton
      currentFolder={{files: {models: []}}}
      showingButtons={true}
      contextId="1"
      contextType="user"
      {...overrides}
    />
  )
}
describe('Files UploadButton', () => {
  it('shows the button', () => {
    const {getByText} = renderUploadButton()
    expect(getByText('Upload')).toBeInTheDocument()
  })

  it('adds hidden-phone classname', () => {
    const {container} = renderUploadButton()
    const noTextOnPhone = container.querySelector('.hidden-phone')
    expect(noTextOnPhone).toBeInTheDocument()
  })

  it('hides actual file input form', () => {
    const {container} = renderUploadButton()
    const form = container.querySelector('form')
    expect(form.classList.contains('hidden')).toBeTruthy()
  })

  it('disables the button while there are uploads in progress', () => {
    const {getByText} = renderUploadButton()

    expect(getByText('Upload').closest('button')).not.toBeDisabled()
    act(() => {
      UploadQueue.pendingUploads = jest.fn().mockReturnValue(1)
      UploadQueue.onChange()
    })
    expect(getByText('Upload').closest('button')).toBeDisabled()
  })
})
