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

import EmbedOptionsTray from '..'
import EmbedOptionsTrayDriver from './EmbedOptionsTrayDriver'

describe('RCE "Embeds" Plugin > EmbedOptionsTray', () => {
  let props
  let tray

  beforeEach(() => {
    props = {
      content: {
        displayAs: 'link',
        text: 'Syllabus.doc',
        url: 'http://example.instructure.com/files/3201/download'
      },
      onRequestClose: jest.fn(),
      onSave: jest.fn(),
      open: true
    }
  })

  function renderComponent() {
    render(<EmbedOptionsTray {...props} />)
    tray = EmbedOptionsTrayDriver.find()
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

  it('is labeled with "Embed Options Tray"', () => {
    renderComponent()
    expect(tray.label).toEqual('Embed Options Tray')
  })

  describe('"Text" field', () => {
    it('uses the value of .text in the given content', () => {
      renderComponent()
      expect(tray.text).toEqual(props.content.text)
    })
  })

  describe('"Link" field', () => {
    it('uses the value of .url in the given content', () => {
      renderComponent()
      expect(tray.link).toEqual(props.content.url)
    })
  })

  describe('"Display Options" field', () => {
    it('uses the value of .displayAs in the given content', () => {
      props.content.displayAs = 'embed'
      renderComponent()
      expect(tray.displayAs).toEqual('embed')
    })

    it('can be set to "Embed Preview"', () => {
      renderComponent()
      tray.setDisplayAs('embed')
      expect(tray.displayAs).toEqual('embed')
    })

    it('can be reset to "Display Text Link"', () => {
      renderComponent()
      tray.setDisplayAs('embed')
      tray.setDisplayAs('link')
      expect(tray.displayAs).toEqual('link')
    })
  })

  describe('"Done" button', () => {
    describe('when Text is not present', () => {
      beforeEach(() => {
        renderComponent()
        tray.setText('')
      })

      it('is disabled', () => {
        expect(tray.$doneButton.disabled).toBe(true)
      })

      it('does not call the .onSave prop when clicked', () => {
        tray.$doneButton.click()
        expect(props.onSave).toHaveBeenCalledTimes(0)
      })
    })

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

        it('includes the Link', () => {
          tray.setLink('http://example.instructure.com/files/3299/download')
          tray.$doneButton.click()
          const [{url}] = props.onSave.mock.calls[0]
          expect(url).toEqual('http://example.instructure.com/files/3299/download')
        })

        it('includes the "Display As" setting', () => {
          tray.setDisplayAs('embed')
          tray.$doneButton.click()
          const [{displayAs}] = props.onSave.mock.calls[0]
          expect(displayAs).toEqual('embed')
        })
      })
    })
  })
})
