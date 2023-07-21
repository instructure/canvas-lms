// /*
//  * Copyright (C) 2020 - present Instructure, Inc.
//  *
//  * This file is part of Canvas.
//  *
//  * Canvas is free software: you can redistribute it and/or modify it under
//  * the terms of the GNU Affero General Public License as published by the Free
//  * Software Foundation, version 3 of the License.
//  *
//  * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
//  * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
//  * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
//  * details.
//  *
//  * You should have received a copy of the GNU Affero General Public License along
//  * with this program. If not, see <http://www.gnu.org/licenses/>.
//  */

test('placeholder test', () => {})

// import {fireEvent, render} from '@testing-library/react'
// import React from 'react'
// import {MediaUploadModal} from '../MediaUploadModal'

// const setup = props => {
//   return render(
//     <MediaUploadModal onFileUpload={() => {}} onRecordingSave={() => {}} open {...props} />
//   )
// }

// describe('MediaUploadModal', () => {
//   it('renders', () => {
//     const {container} = setup()
//     expect(container).toBeTruthy()
//   })

//   it('fires onFileUpload on file upload', async () => {
//     const onFileUploadSpy = jest.fn()
//     const {getByText, getByLabelText} = setup({onFileUpload: onFileUploadSpy})
//     const uploadFilesTab = getByText('Upload Media')
//     fireEvent.click(uploadFilesTab)
//     const selectAudioFile = getByText('Select Audio File')
//     fireEvent.click(selectAudioFile)

//     const fileInputField = getByLabelText('File Upload')
//     const event = {
//       target: {
//         value: ''
//       }
//     }
//     fireEvent.change(fileInputField, event)
//     expect(onFileUploadSpy.mock.calls.length).toBe(1)
//   })

//   it('fires onClose when modal is closed', () => {
//     const onCloseSpy = jest.fn()
//     const {getByText} = setup({
//       onClose: onCloseSpy
//     })
//     const close = getByText('Close')
//     fireEvent.click(close)
//     expect(onCloseSpy.mock.calls.length).toBe(1)
//   })

//   it('fires onOpen when modal is opened', () => {
//     const onOpenSpy = jest.fn()
//     const {rerender} = setup({onOpen: onOpenSpy, open: false})
//     rerender(
//       <MediaUploadModal
//         onFileUpload={() => {}}
//         onOpen={onOpenSpy}
//         onRecordingSave={() => {}}
//         open
//       />
//     )
//     expect(onOpenSpy.mock.calls.length).toBe(1)
//   })
// })
