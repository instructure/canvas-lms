/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import moxios from 'moxios'
import sinon from 'sinon'
import {fireEvent, render, waitFor} from '@testing-library/react'
import {AnnotatedDocumentSelector} from '../EditAssignment'

describe('AnnotatedDocumentSelector', () => {
  describe('when attachment prop is present', () => {
    const filename = 'test.pdf'
    let props

    beforeEach(() => {
      props = {
        attachment: {name: filename},
        onSelect() {},
        onRemove() {},
      }
    })

    it('renders the attachment name', () => {
      const {queryByText} = render(<AnnotatedDocumentSelector {...props} />)
      expect(queryByText(filename)).toBeInTheDocument()
    })

    it('renders a button for removing the attachment', () => {
      const {queryByText} = render(<AnnotatedDocumentSelector {...props} />)
      expect(queryByText('Remove selected attachment')).toBeInTheDocument()
    })

    it('the button for removing the attachment calls onRemove', () => {
      props.onRemove = sinon.stub()
      const {queryByText} = render(<AnnotatedDocumentSelector {...props} />)
      const button = queryByText('Remove selected attachment')
      button.click()
      expect(props.onRemove.callCount).toBe(1)
    })
  })

  describe('when attachment prop is not present', () => {
    let props

    const courseFolder = {
      id: 1,
      name: 'Course files',
      context_id: 1,
      context_type: 'course',
      can_upload: true,
      locked_for_user: false,
      parent_folder_id: null,
    }

    const files = [
      {
        id: 2,
        display_name: 'thumbnail.jpg',
        folder_id: 1,
        thumbnail_url: 'thumbnail.jpg',
        'content-type': 'text/html',
      },
    ]

    beforeEach(() => {
      props = {
        attachment: null,
        onSelect() {},
        onRemove() {},
      }

      window.ENV = {context_asset_string: 'courses_1'}
      moxios.install()

      moxios.stubRequest('/api/v1/courses/1/folders/root', {
        status: 200,
        responseText: courseFolder,
        headers: {link: 'url; rel="current"'},
      })

      moxios.stubRequest('/api/v1/folders/1/files', {
        status: 200,
        responseText: files,
        headers: {link: 'url; rel="current"'},
      })
    })

    afterEach(() => {
      moxios.uninstall()
      window.ENV = {}
    })

    describe('FileBrowser', () => {
      it('renders a FileBrowser', () => {
        const {getByText} = render(<AnnotatedDocumentSelector {...props} />)

        expect(getByText('Loading')).toBeInTheDocument()

        waitFor(() => {
          expect(getByText('Available folders')).toBeInTheDocument()
        })
      })

      it('selecting a file in the FileBrowser calls onSelect', () => {
        props.onSelect = sinon.stub()
        const {queryByText} = render(<AnnotatedDocumentSelector {...props} />)

        waitFor(() => {
          fireEvent.click(queryByText('Course files'))
          fireEvent.click(queryByText('thumbnail.jpg'))
          expect(props.onSelect.callCount).toBe(1)
        })
      })
    })
  })
})
