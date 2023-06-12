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

import fetchMock from 'fetch-mock'
import {renderHook, act} from '@testing-library/react-hooks/dom'
import {useSvgSettings, statuses} from '../settings'
import Editor from '../../../../__tests__/FakeEditor'

jest.mock('../../../shared/ImageCropper/imageCropUtils', () => ({
  createCroppedImageSvg: jest.fn().mockReturnValue(
    Promise.resolve({
      outerHTML: null,
    })
  ),
}))

jest.mock('../../../shared/fileUtils', () => {
  return {
    convertFileToBase64: jest
      .fn()
      .mockReturnValue(Promise.resolve('data:image/svg+xml;base64,CROPPED')),
  }
})

describe('useSvgSettings()', () => {
  let editing, ed
  const canvasOrigin = 'https://domain.from.env'

  beforeEach(() => {
    ed = new Editor()
  })

  const subject = () => renderHook(() => useSvgSettings(ed, editing, canvasOrigin)).result

  describe('when a new icon is being created (not editing)', () => {
    beforeEach(() => {
      editing = false
      global.fetch = jest.fn()
    })

    it('initializes settings to the default', () => {
      const [settings, ,] = subject().current

      expect(settings).toMatchInlineSnapshot(`
        Object {
          "alt": "",
          "color": null,
          "embedImage": null,
          "error": null,
          "externalHeight": null,
          "externalStyle": null,
          "externalWidth": null,
          "height": 0,
          "imageSettings": null,
          "isDecorative": false,
          "outlineColor": "#000000",
          "outlineSize": "none",
          "shape": "square",
          "size": "small",
          "text": "",
          "textBackgroundColor": null,
          "textColor": "#000000",
          "textPosition": "below",
          "textSize": "small",
          "transform": "",
          "translateX": 0,
          "translateY": 0,
          "type": "image/svg+xml-icon-maker-icons",
          "width": 0,
          "x": 0,
          "y": 0,
        }
      `)
    })

    it('sets status to "IDLE"', () => {
      const [, status] = subject().current

      expect(status).toEqual(statuses.IDLE)
    })

    it('does not attempt to fetch an existing SVG', () => {
      expect(global.fetch).not.toHaveBeenCalled()
    })

    it('returns dispatch', () => {
      const [, , dispatch] = subject().current

      expect(typeof dispatch).toEqual('function')
    })

    describe('and a setting update action is dispatched', () => {
      let settingsUpdate

      beforeEach(() => (settingsUpdate = {name: 'Banana', size: 'large'}))

      it('updates the relevant settings', async () => {
        const result = subject()
        act(() => result.current[2](settingsUpdate))
        expect(result.current[0]).toMatchInlineSnapshot(`
          Object {
            "alt": "",
            "color": null,
            "embedImage": null,
            "error": null,
            "externalHeight": null,
            "externalStyle": null,
            "externalWidth": null,
            "height": 0,
            "imageSettings": null,
            "isDecorative": false,
            "name": "Banana",
            "outlineColor": "#000000",
            "outlineSize": "none",
            "shape": "square",
            "size": "large",
            "text": "",
            "textBackgroundColor": null,
            "textColor": "#000000",
            "textPosition": "below",
            "textSize": "small",
            "transform": "",
            "translateX": 0,
            "translateY": 0,
            "type": "image/svg+xml-icon-maker-icons",
            "width": 0,
            "x": 0,
            "y": 0,
          }
        `)
      })
    })
  })

  describe('when an existing icon is being edited', () => {
    let mock
    let body

    beforeEach(() => {
      editing = true

      // Add an image to the editor and select it
      ed.setContent(
        '<img id="test-image" data-inst-icon-maker-icon="true" src="https://canvas.instructure.com/svg" data-download-url="https://canvas.instructure.com/files/1/download" alt="a red circle" />'
      )

      ed.setSelectedNode(ed.dom.select('#test-image')[0])

      //
      // NOTE: 'name' and 'alt' are no longer valid properties in embedded metadata
      // But we're leaving it here to test what happens with pre-existing
      // Icon Maker icons that have it
      //
      body = `
          {
            "name":"Test Icon",
            "alt":"a test image",
            "shape":"triangle",
            "size":"large",
            "color":"#FF2717",
            "outlineColor":"#06A3B7",
            "outlineSize":"small",
            "text":"Some Text",
            "textSize":"medium",
            "textColor":"#009606",
            "textBackgroundColor":"#06A3B7",
            "textPosition":"below"
          }`

      // Stub fetch to return an SVG file
      mock = fetchMock.mock({
        name: 'icon_metadata',
        matcher: '*',
        response: () => ({body}),
      })
    })

    afterEach(() => {
      fetchMock.restore()
    })

    const overwriteUrl = () =>
      (mock = fetchMock.mock({
        name: 'icon_metadata',
        matcher: '*',
        response: () => ({body}),
        overwriteRoutes: true,
      }))

    it('fetches the icon metadata, specifying the course ID and timestamp', () => {
      subject()

      expect(mock.called('icon_metadata')).toBe(true)
      expect(mock.calls('icon_metadata')[0][0]).toMatch(
        /https:\/\/domain.from.env\/api\/v1\/files\/1\/icon_metadata/
      )
    })

    describe('when the download URL contains a course ID', () => {
      beforeEach(() => {
        ed.setContent(
          '<img id="test-image" data-inst-icon-maker-icon="true" src="https://canvas.instructure.com/svg" data-download-url="courses/2/files/1/download" alt="a red circle" />'
        )
        ed.setSelectedNode(ed.dom.select('#test-image')[0])
      })

      it('fetches the icon metadata using the /files/:file_id/icon_metadata endpoint', () => {
        subject()

        expect(mock.called('icon_metadata')).toBe(true)
        expect(mock.calls('icon_metadata')[0][0]).toMatch(
          /https:\/\/domain.from.env\/api\/v1\/files\/1\/icon_metadata/
        )
      })
    })

    describe('with a relative download URL', () => {
      beforeEach(() => {
        ed.setContent(
          '<img id="test-image" data-inst-icon-maker-icon="true" src="https://canvas.instructure.com/svg" data-download-url="/files/1/download" alt="a red circle" />'
        )
        ed.setSelectedNode(ed.dom.select('#test-image')[0])
      })

      it('fetches the icon metadata, specifying the course ID and timestamp', () => {
        subject()
        const calledUrl = mock.calls('icon_metadata')[0][0]
        expect(calledUrl).toMatch(/https:\/\/domain.from.env\/api\/v1\/files\/1\/icon_metadata/)
      })
    })

    describe('with a containing element selected', () => {
      beforeEach(() => {
        ed.setContent(
          '<p id="containing"><img data-inst-icon-maker-icon="true" src="https://canvas.instructure.com/svg" data-download-url="/files/1/download" alt="a red circle" /></p>'
        )
        ed.setSelectedNode(ed.dom.select('#containing')[0])
      })

      it('fetches the icon metadata, specifying the course ID and timestamp', () => {
        subject()
        const calledUrl = mock.calls('icon_metadata')[0][0]
        expect(calledUrl).toMatch(/https:\/\/domain.from.env\/api\/v1\/files\/1\/icon_metadata/)
      })
    })

    it('parses the SVG settings from the icon metadata', async () => {
      const {result, waitForValueToChange} = renderHook(() =>
        useSvgSettings(ed, editing, canvasOrigin)
      )

      await waitForValueToChange(() => {
        return result.current[0]
      })

      expect(result.current[0]).toMatchInlineSnapshot(`
        Object {
          "alt": "a red circle",
          "color": "#FF2717",
          "embedImage": null,
          "error": null,
          "externalHeight": null,
          "externalStyle": null,
          "externalWidth": null,
          "height": 0,
          "imageSettings": null,
          "isDecorative": false,
          "name": "Test Icon",
          "originalName": "Test Icon",
          "outlineColor": "#06A3B7",
          "outlineSize": "small",
          "shape": "triangle",
          "size": "large",
          "text": "Some Text",
          "textBackgroundColor": "#06A3B7",
          "textColor": "#009606",
          "textPosition": "below",
          "textSize": "medium",
          "transform": "",
          "translateX": 0,
          "translateY": 0,
          "type": "image/svg+xml-icon-maker-icons",
          "width": 0,
          "x": 0,
          "y": 0,
        }
      `)
    })

    describe('parses the SVG settings from a legacy SVG metadata structure', () => {
      const bodyGenerator = overrideParams => `
        ${JSON.stringify({
          ...{
            name: 'Test Icon',
            alt: 'a test image',
            shape: 'triangle',
            size: 'large',
            color: '#FF2717',
            outlineColor: '#06A3B7',
            outlineSize: 'small',
            text: 'Some Text',
            textSize: 'medium',
            textColor: '#009606',
            textBackgroundColor: '#06A3B7',
            textPosition: 'below',
            imageSettings: {
              cropperSettings: null,
              icon: {
                label: 'Art Icon',
              },
              iconFillColor: '#FFFFFF',
              image: 'Art Icon',
              mode: 'SingleColor',
            },
          },
          ...overrideParams,
        })}`

      beforeEach(() => {
        // Legacy metadata structure
        body = bodyGenerator()
        overwriteUrl(body)
      })

      it('replaces icon type from object to string for single-color images', async () => {
        const {result, waitForValueToChange} = renderHook(() =>
          useSvgSettings(ed, editing, canvasOrigin)
        )

        await waitForValueToChange(() => {
          return result.current[0]
        })

        expect(result.current[0]).toMatchInlineSnapshot(`
          Object {
            "alt": "a red circle",
            "color": "#FF2717",
            "embedImage": "Art Icon",
            "error": null,
            "externalHeight": null,
            "externalStyle": null,
            "externalWidth": null,
            "height": 0,
            "imageSettings": Object {
              "cropperSettings": null,
              "icon": "art",
              "iconFillColor": "#FFFFFF",
              "image": "Art Icon",
              "mode": "SingleColor",
            },
            "isDecorative": false,
            "name": "Test Icon",
            "originalName": "Test Icon",
            "outlineColor": "#06A3B7",
            "outlineSize": "small",
            "shape": "triangle",
            "size": "large",
            "text": "Some Text",
            "textBackgroundColor": "#06A3B7",
            "textColor": "#009606",
            "textPosition": "below",
            "textSize": "medium",
            "transform": "",
            "translateX": 0,
            "translateY": 0,
            "type": "image/svg+xml-icon-maker-icons",
            "width": 0,
            "x": 0,
            "y": 0,
          }
        `)
      })

      it('replaces icon type from object to string for single-color images even using another language', async () => {
        body = bodyGenerator({
          imageSettings: {
            cropperSettings: null,
            icon: {
              // Spanish label
              label: 'Ícono de arte',
            },
            iconFillColor: '#FFFFFF',
            image: 'Art Icon',
            mode: 'SingleColor',
          },
        })
        overwriteUrl()

        const {result, waitForValueToChange} = renderHook(() =>
          useSvgSettings(ed, editing, canvasOrigin)
        )

        await waitForValueToChange(() => {
          return result.current[0]
        })

        expect(result.current[0]).toMatchInlineSnapshot(`
          Object {
            "alt": "a red circle",
            "color": "#FF2717",
            "embedImage": "Art Icon",
            "error": null,
            "externalHeight": null,
            "externalStyle": null,
            "externalWidth": null,
            "height": 0,
            "imageSettings": Object {
              "cropperSettings": null,
              "icon": "art",
              "iconFillColor": "#FFFFFF",
              "image": "Art Icon",
              "mode": "SingleColor",
            },
            "isDecorative": false,
            "name": "Test Icon",
            "originalName": "Test Icon",
            "outlineColor": "#06A3B7",
            "outlineSize": "small",
            "shape": "triangle",
            "size": "large",
            "text": "Some Text",
            "textBackgroundColor": "#06A3B7",
            "textColor": "#009606",
            "textPosition": "below",
            "textSize": "medium",
            "transform": "",
            "translateX": 0,
            "translateY": 0,
            "type": "image/svg+xml-icon-maker-icons",
            "width": 0,
            "x": 0,
            "y": 0,
          }
        `)
      })

      it('sets image settings to null when label is not found', async () => {
        body = bodyGenerator({
          imageSettings: {
            cropperSettings: null,
            icon: {
              // Invalid label
              label: 'Banana',
            },
            iconFillColor: '#FFFFFF',
            image: 'Art Icon',
            mode: 'SingleColor',
          },
        })
        overwriteUrl()

        const {result, waitForValueToChange} = renderHook(() =>
          useSvgSettings(ed, editing, canvasOrigin)
        )

        await waitForValueToChange(() => {
          return result.current[0]
        })

        expect(result.current[0]).toMatchInlineSnapshot(`
          Object {
            "alt": "a red circle",
            "color": "#FF2717",
            "embedImage": null,
            "error": null,
            "externalHeight": null,
            "externalStyle": null,
            "externalWidth": null,
            "height": 0,
            "imageSettings": null,
            "isDecorative": false,
            "name": "Test Icon",
            "originalName": "Test Icon",
            "outlineColor": "#06A3B7",
            "outlineSize": "small",
            "shape": "triangle",
            "size": "large",
            "text": "Some Text",
            "textBackgroundColor": "#06A3B7",
            "textColor": "#009606",
            "textPosition": "below",
            "textSize": "medium",
            "transform": "",
            "translateX": 0,
            "translateY": 0,
            "type": "image/svg+xml-icon-maker-icons",
            "width": 0,
            "x": 0,
            "y": 0,
          }
        `)
      })

      it('sets image to the original one stored in cropper settings', async () => {
        body = bodyGenerator({
          imageSettings: {
            cropperSettings: {
              image: 'data:image/svg+xml;base64,aaa',
              shape: 'triangle',
            },
            image: 'data:image/svg+xml;base64,bbb',
            mode: 'Course',
          },
        })
        overwriteUrl()

        const {result, waitForValueToChange} = renderHook(() =>
          useSvgSettings(ed, editing, canvasOrigin)
        )

        await waitForValueToChange(() => {
          return result.current[0]
        })

        expect(result.current[0]).toMatchInlineSnapshot(`
          Object {
            "alt": "a red circle",
            "color": "#FF2717",
            "embedImage": "data:image/svg+xml;base64,CROPPED",
            "error": null,
            "externalHeight": null,
            "externalStyle": null,
            "externalWidth": null,
            "height": 0,
            "imageSettings": Object {
              "cropperSettings": Object {
                "shape": "triangle",
              },
              "image": "data:image/svg+xml;base64,aaa",
              "mode": "Course",
            },
            "isDecorative": false,
            "name": "Test Icon",
            "originalName": "Test Icon",
            "outlineColor": "#06A3B7",
            "outlineSize": "small",
            "shape": "triangle",
            "size": "large",
            "text": "Some Text",
            "textBackgroundColor": "#06A3B7",
            "textColor": "#009606",
            "textPosition": "below",
            "textSize": "medium",
            "transform": "",
            "translateX": 0,
            "translateY": 0,
            "type": "image/svg+xml-icon-maker-icons",
            "width": 0,
            "x": 0,
            "y": 0,
          }
        `)
      })

      it('removes old image fields from metadata', async () => {
        body = bodyGenerator({
          encodedImage: 'banana',
          encodedImageType: 'kiwi',
          encodedImageName: 'peanut',
          imageSettings: {
            cropperSettings: {
              shape: 'triangle',
            },
            image: 'data:image/svg+xml;base64,bbb',
            mode: 'Course',
          },
        })
        overwriteUrl()

        const {result, waitForValueToChange} = renderHook(() =>
          useSvgSettings(ed, editing, canvasOrigin)
        )

        await waitForValueToChange(() => {
          return result.current[0]
        })

        expect(result.current[0]).toMatchInlineSnapshot(`
          Object {
            "alt": "a red circle",
            "color": "#FF2717",
            "embedImage": "data:image/svg+xml;base64,CROPPED",
            "error": null,
            "externalHeight": null,
            "externalStyle": null,
            "externalWidth": null,
            "height": 0,
            "imageSettings": Object {
              "cropperSettings": Object {
                "shape": "triangle",
              },
              "image": "data:image/svg+xml;base64,bbb",
              "mode": "Course",
            },
            "isDecorative": false,
            "name": "Test Icon",
            "originalName": "Test Icon",
            "outlineColor": "#06A3B7",
            "outlineSize": "small",
            "shape": "triangle",
            "size": "large",
            "text": "Some Text",
            "textBackgroundColor": "#06A3B7",
            "textColor": "#009606",
            "textPosition": "below",
            "textSize": "medium",
            "transform": "",
            "translateX": 0,
            "translateY": 0,
            "type": "image/svg+xml-icon-maker-icons",
            "width": 0,
            "x": 0,
            "y": 0,
          }
        `)
      })
    })

    it('sets the status to "loading"', () => {
      const result = subject()
      expect(result.current[1]).toEqual(statuses.LOADING)
    })

    it('returns the status to "idle"', async () => {
      const {result, waitForValueToChange} = renderHook(() =>
        useSvgSettings(ed, editing, canvasOrigin)
      )

      await waitForValueToChange(() => {
        return result.current[1]
      })

      expect(result.current[1]).toEqual(statuses.IDLE)
    })

    describe('and the metadata is non-parsable', () => {
      body = `
        <svg height="100" width="100">
          <circle cx="50" cy="50" r="40" stroke="black" stroke-width="3" fill="red"/>
        </svg>
      `

      it('uses the default settings', () => {
        const result = subject()
        expect(result.current[0]).toMatchInlineSnapshot(`
          Object {
            "alt": "",
            "color": null,
            "embedImage": null,
            "error": null,
            "externalHeight": null,
            "externalStyle": null,
            "externalWidth": null,
            "height": 0,
            "imageSettings": null,
            "isDecorative": false,
            "outlineColor": "#000000",
            "outlineSize": "none",
            "shape": "square",
            "size": "small",
            "text": "",
            "textBackgroundColor": null,
            "textColor": "#000000",
            "textPosition": "below",
            "textSize": "small",
            "transform": "",
            "translateX": 0,
            "translateY": 0,
            "type": "image/svg+xml-icon-maker-icons",
            "width": 0,
            "x": 0,
            "y": 0,
          }
        `)
      })
    })

    describe('and the selected node has no src', () => {
      beforeEach(() => ed.setSelectedNode())

      it('uses the default settings', async () => {
        const result = subject()
        expect(result.current[0]).toMatchInlineSnapshot(`
          Object {
            "alt": "",
            "color": null,
            "embedImage": null,
            "error": null,
            "externalHeight": null,
            "externalStyle": null,
            "externalWidth": null,
            "height": 0,
            "imageSettings": null,
            "isDecorative": false,
            "outlineColor": "#000000",
            "outlineSize": "none",
            "shape": "square",
            "size": "small",
            "text": "",
            "textBackgroundColor": null,
            "textColor": "#000000",
            "textPosition": "below",
            "textSize": "small",
            "transform": "",
            "translateX": 0,
            "translateY": 0,
            "type": "image/svg+xml-icon-maker-icons",
            "width": 0,
            "x": 0,
            "y": 0,
          }
        `)
      })
    })

    it('sets embed image when there cropper settings exist', async () => {
      body = `
          {
            "name":"Test Icon",
            "alt":"a test image",
            "shape":"triangle",
            "size":"large",
            "color":"#FF2717",
            "outlineColor":"#06A3B7",
            "outlineSize":"small",
            "text":"Some Text",
            "textSize":"medium",
            "textColor":"#009606",
            "textBackgroundColor":"#06A3B7",
            "textPosition":"below",
            "imageSettings": {
              "cropperSettings": {
                "shape": "triangle"
              },
              "image": "data:image/svg+xml;base64,ORIGINAL"
            }
          }`
      overwriteUrl()

      const {result, waitForValueToChange} = renderHook(() =>
        useSvgSettings(ed, editing, canvasOrigin)
      )

      await waitForValueToChange(() => {
        return result.current[0]
      })

      expect(result.current[0]).toMatchInlineSnapshot(`
        Object {
          "alt": "a red circle",
          "color": "#FF2717",
          "embedImage": "data:image/svg+xml;base64,CROPPED",
          "error": null,
          "externalHeight": null,
          "externalStyle": null,
          "externalWidth": null,
          "height": 0,
          "imageSettings": Object {
            "cropperSettings": Object {
              "shape": "triangle",
            },
            "image": "data:image/svg+xml;base64,ORIGINAL",
          },
          "isDecorative": false,
          "name": "Test Icon",
          "originalName": "Test Icon",
          "outlineColor": "#06A3B7",
          "outlineSize": "small",
          "shape": "triangle",
          "size": "large",
          "text": "Some Text",
          "textBackgroundColor": "#06A3B7",
          "textColor": "#009606",
          "textPosition": "below",
          "textSize": "medium",
          "transform": "",
          "translateX": 0,
          "translateY": 0,
          "type": "image/svg+xml-icon-maker-icons",
          "width": 0,
          "x": 0,
          "y": 0,
        }
      `)
    })

    it('sets embed image when there cropper settings do not exist', async () => {
      body = `
          {
            "name":"Test Icon",
            "alt":"a test image",
            "shape":"triangle",
            "size":"large",
            "color":"#FF2717",
            "outlineColor":"#06A3B7",
            "outlineSize":"small",
            "text":"Some Text",
            "textSize":"medium",
            "textColor":"#009606",
            "textBackgroundColor":"#06A3B7",
            "textPosition":"below",
            "imageSettings": {
              "image": "data:image/svg+xml;base64,ORIGINAL"
            }
          }`
      overwriteUrl()

      const {result, waitForValueToChange} = renderHook(() =>
        useSvgSettings(ed, editing, canvasOrigin)
      )

      await waitForValueToChange(() => {
        return result.current[0]
      })

      expect(result.current[0]).toMatchInlineSnapshot(`
        Object {
          "alt": "a red circle",
          "color": "#FF2717",
          "embedImage": "data:image/svg+xml;base64,ORIGINAL",
          "error": null,
          "externalHeight": null,
          "externalStyle": null,
          "externalWidth": null,
          "height": 0,
          "imageSettings": Object {
            "image": "data:image/svg+xml;base64,ORIGINAL",
          },
          "isDecorative": false,
          "name": "Test Icon",
          "originalName": "Test Icon",
          "outlineColor": "#06A3B7",
          "outlineSize": "small",
          "shape": "triangle",
          "size": "large",
          "text": "Some Text",
          "textBackgroundColor": "#06A3B7",
          "textColor": "#009606",
          "textPosition": "below",
          "textSize": "medium",
          "transform": "",
          "translateX": 0,
          "translateY": 0,
          "type": "image/svg+xml-icon-maker-icons",
          "width": 0,
          "x": 0,
          "y": 0,
        }
      `)
    })

    it('cleans image settings when there is no icon or image embed', async () => {
      body = `
          {
            "name":"Test Icon",
            "alt":"a test image",
            "shape":"triangle",
            "size":"large",
            "color":"#FF2717",
            "outlineColor":"#06A3B7",
            "outlineSize":"small",
            "text":"Some Text",
            "textSize":"medium",
            "textColor":"#009606",
            "textBackgroundColor":"#06A3B7",
            "textPosition":"below",
            "imageSettings": {
              "mode": "",
              "image": "",
              "imageName": "",
              "icon": "",
              "iconFillColor": "#000000",
              "cropperSettings": {
                "shape": "square"
              }
            }
          }`
      overwriteUrl()

      const {result, waitForValueToChange} = renderHook(() =>
        useSvgSettings(ed, editing, canvasOrigin)
      )

      await waitForValueToChange(() => {
        return result.current[0]
      })

      expect(result.current[0]).toMatchInlineSnapshot(`
        Object {
          "alt": "a red circle",
          "color": "#FF2717",
          "embedImage": null,
          "error": null,
          "externalHeight": null,
          "externalStyle": null,
          "externalWidth": null,
          "height": 0,
          "imageSettings": null,
          "isDecorative": false,
          "name": "Test Icon",
          "originalName": "Test Icon",
          "outlineColor": "#06A3B7",
          "outlineSize": "small",
          "shape": "triangle",
          "size": "large",
          "text": "Some Text",
          "textBackgroundColor": "#06A3B7",
          "textColor": "#009606",
          "textPosition": "below",
          "textSize": "medium",
          "transform": "",
          "translateX": 0,
          "translateY": 0,
          "type": "image/svg+xml-icon-maker-icons",
          "width": 0,
          "x": 0,
          "y": 0,
        }
      `)
    })

    it("replaces the cropper settings shape with icon's shape it they don't match", async () => {
      body = `
          {
            "name":"Test Icon",
            "alt":"a test image",
            "shape":"triangle",
            "size":"large",
            "color":"#FF2717",
            "outlineColor":"#06A3B7",
            "outlineSize":"small",
            "text":"Some Text",
            "textSize":"medium",
            "textColor":"#009606",
            "textBackgroundColor":"#06A3B7",
            "textPosition":"below",
            "imageSettings": {
              "mode": "Course",
              "image": "data:image/jpeg;base64,SGVsbG8sIFdvcmxkIQ==",
              "imageName": "banana.jpg",
              "icon": "",
              "iconFillColor": "",
              "cropperSettings": {
                "shape": "square"
              }
            }
          }`
      overwriteUrl()

      const {result, waitForValueToChange} = renderHook(() =>
        useSvgSettings(ed, editing, canvasOrigin)
      )

      await waitForValueToChange(() => {
        return result.current[0]
      })

      expect(result.current[0]).toMatchInlineSnapshot(`
        Object {
          "alt": "a red circle",
          "color": "#FF2717",
          "embedImage": "data:image/svg+xml;base64,CROPPED",
          "error": null,
          "externalHeight": null,
          "externalStyle": null,
          "externalWidth": null,
          "height": 0,
          "imageSettings": Object {
            "cropperSettings": Object {
              "shape": "triangle",
            },
            "icon": "",
            "iconFillColor": "",
            "image": "data:image/jpeg;base64,SGVsbG8sIFdvcmxkIQ==",
            "imageName": "banana.jpg",
            "mode": "Course",
          },
          "isDecorative": false,
          "name": "Test Icon",
          "originalName": "Test Icon",
          "outlineColor": "#06A3B7",
          "outlineSize": "small",
          "shape": "triangle",
          "size": "large",
          "text": "Some Text",
          "textBackgroundColor": "#06A3B7",
          "textColor": "#009606",
          "textPosition": "below",
          "textSize": "medium",
          "transform": "",
          "translateX": 0,
          "translateY": 0,
          "type": "image/svg+xml-icon-maker-icons",
          "width": 0,
          "x": 0,
          "y": 0,
        }
      `)
    })
  })

  describe('when an existing icon is edited while the tray is already open', () => {
    beforeEach(() => {
      editing = true

      // Add an image to the editor and select it
      ed.setContent(`
        <img id="test-image-1" src="https://canvas.instructure.com/svg1"
          data-inst-icon-maker-icon="true"
          data-download-url="https://canvas.instructure.com/files/1/download" />
        <img id="test-image-2" src="https://canvas.instructure.com/svg2"
          data-inst-icon-maker-icon="true"
          data-download-url="https://canvas.instructure.com/files/2/download" />
      `)

      fetchMock.mock('begin:https://domain.from.env/api/v1/files/1/icon_metadata', {
        body: `
          {
            "name":"Test Icon.svg",
            "alt":"the first test image",
            "shape":"triangle",
            "size":"large",
            "color":"#FF2717",
            "outlineColor":"#06A3B7",
            "outlineSize":"small",
            "text":"Some Text",
            "textSize":"medium",
            "textColor":"#009606",
            "textBackgroundColor":"#06A3B7",
            "textPosition":"below"
          }`,
      })

      fetchMock.mock('begin:https://domain.from.env/api/v1/files/2/icon_metadata', {
        body: `
          {
            "name":"Test Icon.svg",
            "alt":"the second test image",
            "shape":"square",
            "size":"medium",
            "color":"#FF2717",
            "outlineColor":"#06A3B7",
            "outlineSize":"small",
            "text":"Some Text",
            "textSize":"medium",
            "textColor":"#009606",
            "textBackgroundColor":"#06A3B7",
            "textPosition":"below"
          }`,
      })
    })

    afterEach(() => fetchMock.reset())

    it('loads the correct metadata', async () => {
      const {result, rerender, waitForValueToChange} = renderHook(() =>
        useSvgSettings(ed, editing, canvasOrigin)
      )

      ed.setSelectedNode(ed.dom.select('#test-image-1')[0])
      rerender()
      await waitForValueToChange(() => result.current)

      ed.setSelectedNode(ed.dom.select('#test-image-2')[0])
      rerender()
      await waitForValueToChange(() => result.current)

      expect(result.current[0].name).toEqual('Test Icon')
      expect(result.current[0].shape).toEqual('square')
    })
  })
})
