/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {render, fireEvent, queryByText, } from 'react-testing-library'
import ComputerPanel from '../ComputerPanel'

describe('UploadImage: ComputerPanel', () => {
    it('shows a failure message if the file is rejected', () => {
      const notAnImage = new File(["foo"], "foo.txt", {
        type: "text/plain",
      });
      const handleSetImageFile = jest.fn()
      const handleSetHasUploadedImage = jest.fn()
      const {getByLabelText, getByText} = render(<ComputerPanel imageFile={null}
        setImageFile={handleSetImageFile}
        hasUploadedImage={false}
        setHasUploadedImage={handleSetHasUploadedImage} />)
      const dropZone = getByLabelText(/Upload File/, { selector: 'input' })
      fireEvent.change(dropZone, {
        target: {
          files: [notAnImage]
        }
      })
      expect(getByText('Invalid file type')).toBeVisible()
    })

    it('accepts image files', () => {
        const anImage = new File(["foo"], "foo.png", {
          type: "image/png",
        });
        const handleSetImageFile = jest.fn()
        const handleSetHasUploadedImage = jest.fn()
        const {getByLabelText, queryByText} = render(<ComputerPanel imageFile={null}
          setImageFile={handleSetImageFile}
          hasUploadedImage={false}
          setHasUploadedImage={handleSetHasUploadedImage} />)
        const dropZone = getByLabelText(/Upload File/, { selector: 'input' })
        fireEvent.change(dropZone, {
          target: {
            files: [anImage]
          }
        })
        expect(queryByText('Invalid file type')).toBeNull()
    })

    it('clears error messages if a valid file is added', () => {
      const notAnImage = new File(["foo"], "foo.txt", {
        type: "text/plain",
      });
      const anImage = new File(["foo"], "foo.png", {
        type: "image/png",
      });
      const handleSetImageFile = jest.fn()
      const handleSetHasUploadedImage = jest.fn()
      const {getByLabelText, getByText, queryByText} = render(<ComputerPanel imageFile={null}
        setImageFile={handleSetImageFile}
        hasUploadedImage={false}
        setHasUploadedImage={handleSetHasUploadedImage} />)
      const dropZone = getByLabelText(/Upload File/, { selector: 'input' })
      fireEvent.change(dropZone, {
        target: {
          files: [notAnImage]
        }
      })
      expect(getByText('Invalid file type')).toBeVisible()
      fireEvent.change(dropZone, {
        target: {
          files: [anImage]
        }
      })

      expect(queryByText('Invalid file type')).toBeNull()
    })

    it('shows the image preview when hasUploadedImage is true', () => {
      const anImage = new File(["foo"], "foo.png", {
        type: "image/png",
      });
      const handleSetImageFile = jest.fn()
      const handleSetHasUploadedImage = jest.fn()
      const {getByLabelText} = render(<ComputerPanel imageFile={anImage}
        setImageFile={handleSetImageFile}
        hasUploadedImage={true}
        setHasUploadedImage={handleSetHasUploadedImage} />)
      expect(getByLabelText('foo.png preview')).toBeInTheDocument()
    })

    it('clicking the trash button removes the image preview', () => {
      const anImage = new File(["foo"], "foo.png", {
        type: "image/png",
      });
      const handleSetImageFile = jest.fn()
      const handleSetHasUploadedImage = jest.fn()
      const {getByText} = render(<ComputerPanel imageFile={anImage}
        setImageFile={handleSetImageFile}
        hasUploadedImage={true}
        setHasUploadedImage={handleSetHasUploadedImage} />)
      fireEvent.click(getByText('Clear Upload'))
      expect(handleSetHasUploadedImage).toHaveBeenCalledWith(false)
      expect(handleSetImageFile).toHaveBeenCalledWith(null)
    })
})
