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
import LinkOptionsTray from '..'
import LinkOptionsTrayDriver from './LinkOptionsTrayDriver'

describe('RCE "Links" Plugin > LinkOptionsTray', () => {
  let props
  let tray
  beforeEach(() => {
    props = {
      content: {
        displayAs: 'link',
        text: 'Syllabus.doc',
        url: 'http://example.instructure.com/files/3201/download',
        isPreviewable: true,
        onlyTextSelected: true
      },
      onRequestClose: jest.fn(),
      onSave: jest.fn(),
      open: true
    }
  })
  function renderComponent() {
    render(<LinkOptionsTray {...props} />)
    tray = LinkOptionsTrayDriver.find()
  }
  it('is optionally rendered open', () => {
    props.open = true
    renderComponent()
    expect(tray).not.toBeNull()
  })
  it('is optionally rendered closed', () => {
    props.open = false
    renderComponent()
    expect(tray).toBeNull()
  })
  it('is labeled with "Link Options"', () => {
    renderComponent()
    expect(tray.label).toEqual('Link Options')
  })
  describe('"Text" field', () => {
    it('uses the value of .text in the given content', () => {
      renderComponent()
      expect(tray.text).toEqual(props.content.text)
    })

    it('does not show the text field if something other than text was selected', () => {
      props.content.onlyTextSelected = false
      renderComponent()
      expect(tray.$textField).toBe(null)
    })
  })
  describe('"Link" field', () => {
    it('uses the value of .url in the given content', () => {
      renderComponent()
      expect(tray.link).toEqual(props.content.url)
    })
  })
  describe('"Display Options" field', () => {
    it('is hidden if the link is not previewable', () => {
      props.content.isPreviewable = false
      renderComponent()
      expect(tray.$previewCheckbox).not.toBeInTheDocument()
    })

    it('is shown if the link is previewable', () => {
      renderComponent()
      expect(tray.$displayAsField).toBeInTheDocument()
    })

    it('checks auto-preview if displayAs is "embed"', () => {
      props.content.displayAs = 'embed'
      renderComponent()
      expect(tray.autoPreview).toBeTruthy()
    })
    it('unchecks auto-preview if displayAs is "link"', () => {
      props.content.displayAs = 'link'
      renderComponent()
      expect(tray.autoPreview).toBeFalsy()
    })

    it('can be reset to "Display Text Link"', () => {
      props.content.displayAs = 'link'
      renderComponent()
      tray.setAutoPreview(true)
      expect(tray.autoPreview).toBeTruthy()
      tray.setAutoPreview(false)
      expect(tray.autoPreview).toBeFalsy()
    })
  })
  describe('"Done" button', () => {
    describe('when a Link url is not present', () => {
      beforeEach(() => {
        renderComponent()
        tray.setLink('')
      })
      it('is disabled', () => {
        expect(tray.$doneButton.disabled).toBe(true)
      })
      it('does not call the .onSave prop when clicked', () => {
        tray.$doneButton.click()
        expect(props.onSave).toHaveBeenCalledTimes(0)
      })
    })
    describe('when clicked', () => {
      beforeEach(() => {
        renderComponent()
      })
      it('prevents the default click handler', () => {
        const preventDefault = jest.fn()
        tray.$doneButton.addEventListener(
          'click',
          event => {
            Object.assign(event, {preventDefault})
          },
          true
        )
        tray.$doneButton.click()
        expect(preventDefault).toHaveBeenCalledTimes(1)
      })
      it('calls the .onSave prop', () => {
        tray.$doneButton.click()
        expect(props.onSave).toHaveBeenCalledTimes(1)
      })
      describe('when calling the .onSave prop', () => {
        it('includes the Text', () => {
          tray.setText('Syllabus-revised-final__FINAL (2).doc')
          tray.$doneButton.click()
          const [{text}] = props.onSave.mock.calls[0]
          expect(text).toEqual('Syllabus-revised-final__FINAL (2).doc')
        })

        it('omits embed info if the file is not previewable', () => {
          props.content.isPreviewable = false
          tray.$doneButton.click()
          const [{embed}] = props.onSave.mock.calls[0]
          expect(embed).toBeNull()
        })

        it('includes embed info if the file is previewable', () => {
          props.content.isPreviewable = true
          tray.$doneButton.click()
          const [{embed}] = props.onSave.mock.calls[0]
          expect(embed.type).toEqual('scribd')
          expect(embed.autoOpenPreview).toBeFalsy()
        })

        it('sets autoOpen if the displayAs is "embed"', () => {
          props.content.isPreviewable = true
          tray.setAutoPreview(true)
          tray.$doneButton.click()
          const [{embed}] = props.onSave.mock.calls[0]
          expect(embed.type).toEqual('scribd')
          expect(embed.autoOpenPreview).toBeTruthy()
          expect(embed.disablePreview).toBeFalsy()
        })

        it('sets disablePreview if displayAs is "embed-disabled"', () => {
          props.content.isPreviewable = true
          tray.setDisablePreview(true)
          tray.$doneButton.click()
          const [{embed}] = props.onSave.mock.calls[0]
          expect(embed.type).toEqual('scribd')
          expect(embed.autoOpenPreview).toBeFalsy()
          expect(embed.disablePreview).toBeTruthy()
        })

        it('includes the Link', () => {
          tray.setLink('http://example.instructure.com/files/3299/download')
          tray.$doneButton.click()
          const [{href}] = props.onSave.mock.calls[0]
          expect(href).toEqual('http://example.instructure.com/files/3299/download')
        })
      })
    })
  })
})
