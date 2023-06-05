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
        onlyTextSelected: true,
      },
      onRequestClose: jest.fn(),
      onSave: jest.fn(),
      open: true,
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

    it('shows an error message if the url is invalid', () => {
      props.content.url = 'xxx://example.instructure.com/files/3201/download'
      renderComponent()
      expect(tray.link).toEqual(props.content.url)
      expect(tray.$errorMessage).toBeInTheDocument()
      expect(tray.doneButtonIsDisabled).toBe(true)

      // correct the URL
      tray.setLink('//example.instructure.com/files/3201/download')
      expect(tray.link).toEqual('//example.instructure.com/files/3201/download')
      expect(tray.$errorMessage).toBeNull()
      expect(tray.doneButtonIsDisabled).toBe(false)
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

    it('preview_option is "overlay" and auto-preview is hidden if displayAs is "embed-disabled"', () => {
      props.content.displayAs = 'embed-disabled'
      renderComponent()
      expect(tray.$previewCheckbox).toBeNull()
      expect(tray.previewOption).toBe('overlay')
    })

    it('preview_option is "inline" and auto-preview is shown if displayAs is "link"', () => {
      props.content.displayAs = 'link'
      renderComponent()
      expect(tray.$previewCheckbox).toBeInTheDocument()
      expect(tray.autoPreview).toBeFalsy()
      expect(tray.previewOption).toBe('inline')
    })

    it('preview_option is "inline" and auto-preview is checked if displayAs is "embed"', () => {
      props.content.displayAs = 'embed'
      renderComponent()
      expect(tray.autoPreview).toBeTruthy()
      expect(tray.previewOption).toBe('inline')
    })

    it('preview_option is "disable" and auto-preview is hidden if displayAs is "download-link"', () => {
      props.content.displayAs = 'download-link'
      renderComponent()
      expect(tray.$previewCheckbox).toBeNull()
      expect(tray.previewOption).toBe('disable')
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
    describe('when a Link url is only spaces', () => {
      beforeEach(() => {
        props.content.text = '   '
        renderComponent()
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
      it('prevents the default click handler', () => {
        renderComponent()
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
        renderComponent()
        tray.$doneButton.click()
        expect(props.onSave).toHaveBeenCalledTimes(1)
      })
      describe('when calling the .onSave prop', () => {
        it('includes the Text', () => {
          renderComponent()
          tray.setText('Syllabus-revised-final__FINAL (2).doc')
          tray.$doneButton.click()
          const [{text}] = props.onSave.mock.calls[0]
          expect(text).toEqual('Syllabus-revised-final__FINAL (2).doc')
        })

        it('omits target and class attributes', () => {
          renderComponent()
          tray.$doneButton.click()
          const [linkAttrs] = props.onSave.mock.calls[0]
          expect(linkAttrs.target).toBeUndefined()
          expect(linkAttrs.class).toBeUndefined()
        })

        it('omits embed info if the file is not previewable', () => {
          props.content.isPreviewable = false
          renderComponent()
          tray.$doneButton.click()
          const [linkAttrs] = props.onSave.mock.calls[0]
          expect(linkAttrs.embed).toBeNull()
        })

        it('includes embed info if the file is previewable', () => {
          props.content.isPreviewable = true
          renderComponent()
          tray.$doneButton.click()
          const [{embed}] = props.onSave.mock.calls[0]
          expect(embed.type).toEqual('scribd')
          expect(embed.autoOpenPreview).toBeFalsy()
        })

        it('sets autoOpen if the displayAs is "embed"', () => {
          props.content.isPreviewable = true
          renderComponent()
          tray.setAutoPreview(true)
          tray.$doneButton.click()
          const [{embed}] = props.onSave.mock.calls[0]
          expect(embed.type).toEqual('scribd')
          expect(embed.autoOpenPreview).toBeTruthy()
          expect(embed.disableInlinePreview).toBeFalsy()
        })

        it('includes the Link', () => {
          renderComponent()
          tray.setLink('http://example.instructure.com/files/3299/download')
          tray.$doneButton.click()
          const [{href}] = props.onSave.mock.calls[0]
          expect(href).toEqual('http://example.instructure.com/files/3299/download')
        })
      })

      describe('sets disableInlinePreview', () => {
        it('if preview_option is "overlay"', () => {
          props.content.isPreviewable = true
          renderComponent()
          tray.setPreviewOption('overlay')
          tray.$doneButton.click()
          const [{embed}] = props.onSave.mock.calls[0]
          expect(embed.type).toEqual('scribd')
          expect(embed.autoOpenPreview).toBeFalsy()
          expect(embed.disableInlinePreview).toBeTruthy()
          expect(embed.noPreview).toBeFalsy()
        })

        it('if preview_option is "disable"', () => {
          props.content.isPreviewable = true
          renderComponent()
          tray.setPreviewOption('disable')
          tray.$doneButton.click()
          const [{embed}] = props.onSave.mock.calls[0]
          expect(embed.type).toEqual('scribd')
          expect(embed.autoOpenPreview).toBeFalsy()
          expect(embed.disableInlinePreview).toBeTruthy()
          expect(embed.noPreview).toBeTruthy()
        })
      })
    })
  })
})
