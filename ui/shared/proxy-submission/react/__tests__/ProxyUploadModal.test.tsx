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
import {MockedProvider} from '@apollo/client/testing'
import {render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import ProxyUploadModal, {type ProxyUploadModalProps} from '../ProxyUploadModal'

jest.mock('@canvas/upload-file', () => ({
  uploadFile: jest.fn(() => Promise.resolve({id: '123', display_name: 'my-image.png'})),
}))

const defaultProps: ProxyUploadModalProps = {
  student: {
    id: '50',
    name: 'Penny Lane',
  },
  submission: {
    id: '2501',
  },
  assignment: {
    courseId: '1',
    id: '31',
  },
  open: true,
  onClose: () => Promise.resolve(true),
  reloadSubmission: () => Promise.resolve(true),
}

function renderComponent(overrideProps = {}) {
  const props = {...defaultProps, ...overrideProps}
  return render(
    <MockedProvider>
      <ProxyUploadModal {...props} />
    </MockedProvider>,
  )
}

describe('ProxyUploadModal', () => {
  beforeAll(() => {
    global.DataTransferItem = global.DataTransferItem || class DataTransferItem {}
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders', () => {
    const {getByText} = renderComponent()
    expect(getByText('Upload File')).toBeInTheDocument()
  })

  it('indicates files are being uploaded once added to input', async () => {
    const user = userEvent.setup({delay: null})
    const {getByTestId, findByRole} = renderComponent()
    const input = await waitFor(() => getByTestId('proxyInputFileDrop'))
    const file = new File(['my-image'], 'my-image.png', {type: 'image/png'})
    await user.upload(input, file)
    const alert = await findByRole('alert')
    expect(alert).toHaveTextContent('Uploading files')
  })
})
