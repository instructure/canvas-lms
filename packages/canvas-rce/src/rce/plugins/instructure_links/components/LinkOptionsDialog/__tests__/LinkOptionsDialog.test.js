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
import {render} from '@testing-library/react'

import LinkOptionsDialog from '..'
import LinkOptionsDialogDriver from './LinkOptionsDialogDriver'

describe('RCE "Links" Plugin > LinkOptionsDialog', () => {
  let props
  let dialog

  beforeEach(() => {
    props = {
      text: 'Syllabus.doc',
      url: 'http://example.instructure.com/files/3201/download',
      operation: 'create',
      onRequestClose: jest.fn(),
      onSave: jest.fn(),
      open: true,
    }
  })

  function renderComponent() {
    render(<LinkOptionsDialog {...props} />)
    dialog = LinkOptionsDialogDriver.find(props.operation)
  }

  it('is optionally rendered open', () => {
    props.open = true
    renderComponent()
    expect(dialog).not.toBeNull()
  })

  it('is optionally rendered closed', () => {
    props.open = false
    renderComponent()
    expect(dialog).toBeNull()
  })

  it('is labeled with "Insert Link" when creating a new link', () => {
    renderComponent()
    expect(dialog.label).toEqual('Insert Link')
  })

  it('is labeled with "Create Link" when creating a new link', () => {
    props.operation = 'edit'
    renderComponent()
    expect(dialog.label).toEqual('Edit Link')
  })

  describe('"Text" field', () => {
    it('uses the value of .text in the given content', () => {
      renderComponent()
      expect(dialog.text).toEqual(props.text)
    })
  })

  describe('"Link" field', () => {
    it('uses the value of .url in the given content', () => {
      renderComponent()
      expect(dialog.link).toEqual(props.url)
    })

    it('shows an error message if the url is invalid', () => {
      props.url = 'xxx://example.instructure.com/files/3201/download'
      renderComponent()
      expect(dialog.link).toEqual(props.url)
      expect(dialog.$errorMessage).toBeInTheDocument()
      expect(dialog.doneButtonIsDisabled).toBe(true)

      // correct the URL
      dialog.setLink('//example.instructure.com/files/3201/download')
      expect(dialog.link).toEqual('//example.instructure.com/files/3201/download')
      expect(dialog.$errorMessage).toBeNull()
      expect(dialog.doneButtonIsDisabled).toBe(false)
    })
  })

  describe('"Done" button', () => {
    describe('when a Link url is not present', () => {
      beforeEach(() => {
        renderComponent()
        dialog.setLink('')
      })

      it('is disabled', () => {
        expect(dialog.$doneButton.disabled).toBe(true)
      })

      it('does not call the .onSave prop when clicked', () => {
        dialog.$doneButton.click()
        expect(props.onSave).toHaveBeenCalledTimes(0)
      })
    })

    describe('when clicked', () => {
      beforeEach(() => {
        renderComponent()
      })

      it('prevents the default click handler', () => {
        const preventDefault = jest.fn()
        dialog.$doneButton.addEventListener(
          'click',
          event => {
            Object.assign(event, {preventDefault})
          },
          true
        )
        dialog.$doneButton.click()
        expect(preventDefault).toHaveBeenCalledTimes(1)
      })

      it('calls the .onSave prop', () => {
        dialog.$doneButton.click()
        expect(props.onSave).toHaveBeenCalledTimes(1)
      })

      describe('when calling the .onSave prop', () => {
        it('includes the Text', () => {
          dialog.setText('Syllabus-revised-final__FINAL (2).doc')
          dialog.$doneButton.click()
          const [{text}] = props.onSave.mock.calls[0]
          expect(text).toEqual('Syllabus-revised-final__FINAL (2).doc')
        })

        it('includes the Link', () => {
          dialog.setLink('http://example.instructure.com/files/3299/download')
          dialog.$doneButton.click()
          const [linkAttrs] = props.onSave.mock.calls[0]
          expect(linkAttrs.href).toEqual('http://example.instructure.com/files/3299/download')
          expect(linkAttrs.class).toEqual('inline_disabled')
          expect(linkAttrs.embed).toBeUndefined()
        })

        it('sets the text to the url when missing', () => {
          dialog.setText('')
          dialog.$doneButton.click()
          const [{text}] = props.onSave.mock.calls[0]
          expect(text).toEqual(props.url)
        })
      })
    })
  })
})
