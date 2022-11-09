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
import {render, screen} from '@testing-library/react'

import ImageOptionsTray from '..'
import ImageOptionsTrayDriver from './ImageOptionsTrayDriver'
import {CUSTOM} from '../../ImageEmbedOptions'

jest.useFakeTimers()

describe('RCE "Images" Plugin > ImageOptionsTray', () => {
  let props
  let tray

  beforeEach(() => {
    props = {
      imageOptions: {
        altText: '',
        appliedHeight: 300,
        appliedWidth: 150,
        imageSize: CUSTOM,
        isLinked: false,
        isDecorativeImage: false,
        naturalHeight: 200,
        naturalWidth: 100,
        appliedPercentage: 100,
        usePercentageUnits: false,
        url: 'https://www.fillmurray.com/200/100',
      },
      onRequestClose: jest.fn(),
      onSave: jest.fn(),
      open: true,
      isIconMaker: false,
    }
  })

  function renderComponent() {
    render(<ImageOptionsTray {...props} />)
    tray = ImageOptionsTrayDriver.find()
  }

  describe('when image is an icon maker icon', () => {
    beforeEach(() => {
      props.isIconMaker = true
    })

    afterAll(() => {
      props.isIconMaker = false
    })

    it('opens the tray to edit Icon Options instead of Image Options', () => {
      props.open = true
      render(<ImageOptionsTray {...props} />)
      expect(screen.getByText('Icon Options')).toBeInTheDocument()
      const imageOptionsText = screen.queryByText('Image Options')
      expect(imageOptionsText).not.toBeInTheDocument()
    })

    it('excludes from the tray options that are not related to alt text', () => {
      props.open = true
      render(<ImageOptionsTray {...props} />)
      const displayOptions = screen.queryByText('Display Options')
      const imageSize = screen.queryByText('Size')
      const dimensionType = screen.queryByText('Dimension Type')
      expect(displayOptions).not.toBeInTheDocument()
      expect(imageSize).not.toBeInTheDocument()
      expect(dimensionType).not.toBeInTheDocument()
    })
  })

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

  it('is labeled with "Image Options Tray"', () => {
    renderComponent()
    expect(tray.label).toEqual('Image Options Tray')
  })

  describe('"File URL" field', () => {
    it('uses the value of .url in the given image url', () => {
      renderComponent()
      expect(tray.urlText).toEqual('https://www.fillmurray.com/200/100')
    })

    it('can be set', async () => {
      renderComponent()
      await tray.setUrl('https://www.fillmurray.com/140/100')
      expect(tray.urlText).toEqual('https://www.fillmurray.com/140/100')
    })

    it("doesn't appear when url is not external", () => {
      props.imageOptions.url = 'http://localhost/fake-image.jpg'
      renderComponent()
      expect(tray.$urlField).toBeNull()
    })

    it("appears when url's domain is different than the window's origin", () => {
      props.imageOptions.url = 'https://www.fillmurray.com/140/100'
      renderComponent()
      expect(tray.$urlField).not.toBeNull()
    })

    it("appears when url's domain is an invalid url", () => {
      props.imageOptions.url = 'invalidprotocol://www.fillmurray.com/140/100'
      renderComponent()
      expect(tray.$urlField).not.toBeNull()
    })
  })

  describe('"Alt Text" field', () => {
    it('uses the value of .altText in the given image options', () => {
      props.imageOptions.altText = 'A turtle in a party suit.'
      renderComponent()
      expect(tray.altText).toEqual('A turtle in a party suit.')
    })

    it('is blank when the given image options .altText is blank', () => {
      props.imageOptions.altText = ''
      renderComponent()
      expect(tray.altText).toEqual('')
    })

    it('is enabled when .isDecorativeImage is false in the given image options', () => {
      props.imageOptions.isDecorativeImage = false
      renderComponent()
      expect(tray.altTextDisabled).toEqual(false)
    })
  })

  describe('"No Alt Text" Checkbox', () => {
    it('is checked when .isDecorativeImage is true in the given image options', () => {
      props.imageOptions.isDecorativeImage = true
      renderComponent()
      expect(tray.isDecorativeImage).toEqual(true)
    })

    it('is unchecked when .isDecorativeImage is false in the given image options', () => {
      props.imageOptions.isDecorativeImage = false
      renderComponent()
      expect(tray.isDecorativeImage).toEqual(false)
    })

    it('is enabled when embedding the image', () => {
      renderComponent()
      expect(tray.isDecorativeImageDisabled).toEqual(false)
    })

    it('is disabled when displaying the image as a link', () => {
      renderComponent()
      tray.setDisplayAs('link')
      expect(tray.isDecorativeImageDisabled).toEqual(true)
    })
  })

  describe('"Display Options" field', () => {
    it('is set to "embed" by default', () => {
      renderComponent()
      expect(tray.isDisplayAsDisabled).toBe(false)
      expect(tray.displayAs).toEqual('embed')
    })

    it('can be set to "Display Text Link"', () => {
      renderComponent()
      tray.setDisplayAs('link')
      expect(tray.displayAs).toEqual('link')
    })

    it('can be reset to "Embed Image"', () => {
      renderComponent()
      tray.setDisplayAs('link')
      tray.setDisplayAs('embed')
      expect(tray.displayAs).toEqual('embed')
    })

    it('is hidden when image is already linked', () => {
      props.imageOptions.isLinked = true
      renderComponent()
      expect(tray.isDisplayAsDisabled).toBe(true)
    })
  })

  describe('"Size" field', () => {
    it('is set using the given image options', () => {
      renderComponent()
      expect(tray.size).toEqual('Custom')
    })

    it('can be set to "Small"', async () => {
      renderComponent()
      await tray.setSize('Small')
      expect(tray.size).toEqual('Small')
    })

    it.skip('can be re-set to "Medium"', async () => {
      renderComponent()
      await tray.setSize('Small')
      await tray.setSize('Medium')
      expect(tray.size).toEqual('Medium')
    })

    it('can be set to "Large"', async () => {
      renderComponent()
      await tray.setSize('Large')
      expect(tray.size).toEqual('Large')
    })

    it.skip('can be set to "Custom"', async () => {
      renderComponent()
      await tray.setSize('Small')
      await tray.setSize('Custom')
      expect(tray.size).toEqual('Custom')
    })
  })

  describe('"Done" button', () => {
    describe('when Alt Text is present', () => {
      beforeEach(() => {
        renderComponent()
        tray.setAltText('A turtle in a party suit.')
      })

      it('is enabled when "No Alt Text" is unchecked', () => {
        tray.setIsDecorativeImage(false)
        expect(tray.doneButtonDisabled).toEqual(false)
      })

      it('is enabled when "No Alt Text" is checked', () => {
        tray.setIsDecorativeImage(true)
        expect(tray.doneButtonDisabled).toEqual(false)
      })
    })

    describe('when clicked', () => {
      beforeEach(() => {
        renderComponent()
        tray.setAltText('A turtle in a party suit.')
      })

      it('prevents the default click handler', () => {
        const preventDefault = jest.fn()
        // Override preventDefault before event reaches image
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
        it('includes the url', () => {
          tray.$doneButton.click()
          const [{url}] = props.onSave.mock.calls[0]
          expect(url).toEqual('https://www.fillmurray.com/200/100')
        })

        it('includes the Alt Text', () => {
          tray.setAltText('A turtle in a party suit.')
          tray.$doneButton.click()
          const [{altText}] = props.onSave.mock.calls[0]
          expect(altText).toEqual('A turtle in a party suit.')
        })

        it('includes the "Is Decorative" setting', () => {
          tray.setIsDecorativeImage(true)
          tray.$doneButton.click()
          const [{isDecorativeImage}] = props.onSave.mock.calls[0]
          expect(isDecorativeImage).toEqual(true)
        })

        it('cleans the Alt Text when the "is decorative" setting is true', () => {
          tray.setAltText('A turtle in a party suit.')
          tray.setIsDecorativeImage(true)
          tray.$doneButton.click()
          const [{altText}] = props.onSave.mock.calls[0]
          expect(altText).toEqual('')
        })

        it('ensures there is an Alt Text when the "is decorative" setting is true', () => {
          tray.setAltText('')
          tray.setIsDecorativeImage(true)
          tray.$doneButton.click()
          const [{altText}] = props.onSave.mock.calls[0]
          expect(altText).toEqual('')
        })

        it('includes the "Display As" setting', () => {
          tray.setDisplayAs('link')
          tray.$doneButton.click()
          const [{displayAs}] = props.onSave.mock.calls[0]
          expect(displayAs).toEqual('link')
        })

        it.skip('includes the width to be applied', async () => {
          await tray.setSize('Large')
          tray.$doneButton.click()
          const [{appliedWidth}] = props.onSave.mock.calls[0]
          expect(appliedWidth).toEqual(200)
        })

        it.skip('includes the height to be applied', async () => {
          await tray.setSize('Large')
          tray.$doneButton.click()
          const [{appliedHeight}] = props.onSave.mock.calls[0]
          expect(appliedHeight).toEqual(400)
        })

        it.skip('includes the width and height to be applied', async () => {
          props.appliedPercentage = 95
          props.usePercentageUnits = false
          renderComponent()
          await tray.setSize('Large')
          tray.$doneButton.click()
          const [{appliedWidth, appliedHeight}] = props.onSave.mock.calls[0]
          expect(appliedWidth).toEqual(50)
          expect(appliedHeight).toEqual(50)
        })
      })
    })
  })
})
