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

import {render, fireEvent} from '@testing-library/react'
import React from 'react'
import {Attachment} from '../Attachment'

const setup = props => {
  return render(
    <Attachment
      attachment={{id: '1', display_name: '1', mime_class: 'potato'}}
      onReplace={Function.prototype}
      onDelete={Function.prototype}
      {...props}
    />
  )
}

describe('Attachment', () => {
  it('calls onReplace on double click', () => {
    const onReplaceMock = jest.fn()
    const {getByTestId} = setup({onReplace: onReplaceMock})
    expect(onReplaceMock.mock.calls.length).toBe(0)
    fireEvent.dblClick(getByTestId('attachment'))
    fireEvent.change(getByTestId('replacement-input'))
    expect(onReplaceMock.mock.calls.length).toBe(1)
  })

  it('calls onDelete when clicking the remove button', () => {
    const onDeleteMock = jest.fn()
    const {getByTestId} = setup({onDelete: onDeleteMock})
    expect(onDeleteMock.mock.calls.length).toBe(0)
    fireEvent.mouseOver(getByTestId('attachment'))
    fireEvent.click(getByTestId('remove-button'))
    expect(onDeleteMock.mock.calls.length).toBe(1)
  })

  describe('attachment preview', () => {
    it('renders a paperclip if the mime class is not a standard file type', () => {
      const {container} = setup()
      expect(container.querySelector('svg').getAttribute('name')).toEqual('IconPaperclip')
    })

    it('renders the appropriate icon for the file type', () => {
      const supportedFileIcons = [
        {
          mime_class: 'audio',
          name: 'IconAttachMedia',
        },
        {
          mime_class: 'code',
          name: 'IconCode',
        },
        {
          mime_class: 'doc',
          name: 'IconDocument',
        },
        {
          mime_class: 'file',
          name: 'IconPaperclip',
        },
        {
          mime_class: 'flash',
          name: 'IconPaperclip',
        },
        {
          mime_class: 'folder',
          name: 'IconFolder',
        },
        {
          mime_class: 'folder-locked',
          name: 'IconFolderLocked',
        },
        {
          mime_class: 'html',
          name: 'IconCode',
        },
        {
          mime_class: 'image',
          name: 'IconImage',
        },
        {
          mime_class: 'pdf',
          name: 'IconPdf',
        },
        {
          mime_class: 'ppt',
          name: 'IconMsPpt',
        },
        {
          mime_class: 'text',
          name: 'IconDocument',
        },
        {
          mime_class: 'video',
          name: 'IconAttachMedia',
        },
        {
          mime_class: 'xls',
          name: 'IconMsExcel',
        },
        {
          mime_class: 'zip',
          name: 'IconZipped',
        },
      ]

      supportedFileIcons.forEach(fileType => {
        const {container} = setup({
          attachment: {
            id: '1',
            display_name: `${fileType.mime_class} file`,
            mime_class: fileType.mime_class,
          },
        })
        expect(container.querySelector('svg').getAttribute('name')).toEqual(fileType.name)
      })
    })

    describe('a thumbnail url is provided', () => {
      it('uses a thumbnail image rather than an icon', () => {
        const {container, getByAltText} = setup({
          attachment: {
            id: '1',
            display_name: 'has thumbnail',
            thumbnail_url: 'foo.bar/thumbnail',
            mime_class: 'image',
          },
        })
        expect(container.querySelector('svg')).toBe(null)
        expect(getByAltText('has thumbnail preview')).toBeTruthy()
      })
    })
  })
})
