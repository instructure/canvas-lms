/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {beforeCheck, afterCheck} from '../a11yCheckerHooks'

describe('a11yCheckerHooks', () => {
  let fakeEditor
  let fixturesContainer

  beforeEach(() => {
    fixturesContainer = document.createElement('div')
    fixturesContainer.id = 'fixtures'
    document.body.appendChild(fixturesContainer)

    window.ENV = {
      url_for_high_contrast_tinymce_editor_css: [
        '/base/spec/fixtures/a11yCheckerTest1.css',
        '/base/spec/fixtures/a11yCheckerTest2.css',
      ],
    }

    fakeEditor = {
      dom: {
        styleSheetLoader: {
          load: jest.fn((url, callback) => {
            const link = document.createElement('link')
            link.href = url
            link.type = 'text/css'
            link.rel = 'stylesheet'
            link.onload = callback
            fixturesContainer.appendChild(link)
          }),
        },
        doc: {
          styleSheets: {
            0: {disabled: false},
            1: {disabled: false},
            2: {disabled: false},
            length: 3,
          },
        },
      },
    }
  })

  afterEach(() => {
    fixturesContainer.remove()
    delete window.ENV.url_for_high_contrast_tinymce_editor_css
  })

  describe('beforeCheck', () => {
    it('disables the last two stylesheets in the editor', () => {
      beforeCheck(fakeEditor)
      const ssArray = Array.from(fakeEditor.dom.doc.styleSheets)
      expect(ssArray[0].disabled).toBe(false)
      expect(ssArray[1].disabled).toBe(true)
      expect(ssArray[2].disabled).toBe(true)
    })

    it('loads each high contrast url', () => {
      beforeCheck(fakeEditor)
      expect(fakeEditor.dom.styleSheetLoader.load).toHaveBeenCalledTimes(2)
      window.ENV.url_for_high_contrast_tinymce_editor_css.forEach(url => {
        expect(fakeEditor.dom.styleSheetLoader.load).toHaveBeenCalledWith(url, expect.any(Function))
      })
    })

    it('calls done callback when complete', done => {
      beforeCheck(fakeEditor, () => {
        expect(true).toBe(true)
        done()
      })

      // Simulate all stylesheets loading
      const links = fixturesContainer.querySelectorAll('link')
      links.forEach(link => link.onload())
    })
  })

  describe('afterCheck', () => {
    let removeChildMock

    beforeEach(() => {
      removeChildMock = jest.fn()
      const createStyleSheet = (disabled, href) => ({
        disabled,
        href,
        ownerNode: {
          href,
          parentElement: {
            removeChild: node => {
              removeChildMock(node)
              return node
            },
          },
        },
      })

      fakeEditor.dom.doc.styleSheets = {
        0: createStyleSheet(false, 'default.css'),
        1: createStyleSheet(true, 'nonHC.css'),
        2: createStyleSheet(true, 'nonHC2.css'),
        3: createStyleSheet(false, '/base/spec/fixtures/a11yCheckerTest1.css'),
        4: createStyleSheet(false, '/base/spec/fixtures/a11yCheckerTest2.css'),
        length: 5,
      }
    })

    it('removes only high contrast stylesheets', () => {
      afterCheck(fakeEditor)

      expect(removeChildMock).toHaveBeenCalledTimes(2)
      const calls = removeChildMock.mock.calls
      expect(calls.some(call => call[0].href === '/base/spec/fixtures/a11yCheckerTest1.css')).toBe(
        true,
      )
      expect(calls.some(call => call[0].href === '/base/spec/fixtures/a11yCheckerTest2.css')).toBe(
        true,
      )
    })

    it('enables all previously disabled stylesheets', () => {
      afterCheck(fakeEditor)
      const ssArray = Array.from(fakeEditor.dom.doc.styleSheets)
      expect(ssArray[0].disabled).toBe(false)
      expect(ssArray[1].disabled).toBe(false)
      expect(ssArray[2].disabled).toBe(false)
    })
  })
})
