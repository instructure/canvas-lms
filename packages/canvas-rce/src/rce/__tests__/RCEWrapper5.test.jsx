/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {render, waitFor} from '@testing-library/react'

import RCEWrapper from '../RCEWrapper'

const textareaId = 'myUniqId'
const canvasOrigin = 'https://canvas:3000'

let fakeTinyMCE, editor, rce

function createMountedElement(additionalProps = {}) {
  const rceRef = React.createRef()
  const container = document.getElementById('container')
  const retval = render(
    <RCEWrapper
      ref={rceRef}
      defaultContent="an example string"
      textareaId={textareaId}
      tinymce={fakeTinyMCE}
      editorOptions={{}}
      liveRegion={() => document.getElementById('flash_screenreader_holder')}
      canUploadFiles={false}
      canvasOrigin={canvasOrigin}
      {...trayProps()}
      {...additionalProps}
    />,
    {container},
  )
  rce = rceRef.current
  editor = rce.mceInstance()
  jest.spyOn(rce, 'indicateEditor').mockReturnValue(undefined)
  return retval
}

function trayProps() {
  return {
    trayProps: {
      canUploadFiles: true,
      host: 'rcs.host',
      jwt: 'donotlookatme',
      contextType: 'course',
      contextId: '17',
      containingContext: {
        userId: '1',
        contextType: 'course',
        contextId: '17',
      },
    },
  }
}

describe('RCEWrapper', () => {
  beforeEach(() => {
    document.body.innerHTML = `
     <div id="flash_screenreader_holder" role="alert"/>
      <div id="app">
        <textarea id="${textareaId}"></textarea>
        <div id="container" style="width:500px;height:500px;" />
      </div>
    `
    document.documentElement.dir = 'ltr'

    fakeTinyMCE = {
      triggerSave: () => 'called',
      execCommand: () => 'command executed',
      // plugins
      create: () => {},
      PluginManager: {
        add: () => {},
      },
      plugins: {
        AccessibilityChecker: {},
      },
      get: () => editor,
    }
    global.tinymce = fakeTinyMCE
  })

  afterEach(function () {
    document.body.innerHTML = ''
    jest.restoreAllMocks()
  })

  describe('limit the number or RCEs fully rendered on page load', () => {
    function renderAnotherRCE(callback, additionalProps = {}) {
      const container = document.getElementById('here')
      render(
        <RCEWrapper
          textareaId={textareaId}
          tinymce={fakeTinyMCE}
          editorOptions={{}}
          liveRegion={() => document.getElementById('flash_screenreader_holder')}
          canUploadFiles={false}
          canvasOrigin={canvasOrigin}
          {...trayProps()}
          {...additionalProps}
        />,
        {container},
      )
      if (callback) {
        callback()
      }
    }

    beforeAll(() => {
      if (!('IntersectionObserver' in window)) {
        window.IntersectionObserver = function () {
          return {
            observe: () => {},
            disconnect: () => {},
          }
        }
      }
    })
    beforeEach(() => {
      document.getElementById('app').innerHTML = `
      <div class='rce-wrapper'>faux rendered rce</div>
      <div class='rce-wrapper'>faux rendered rce</div>
      <div id="here"/>
    `
    })

    it('renders them all if no max is set', async () => {
      renderAnotherRCE(async () => {
        await waitFor(() => {
          expect(document.querySelectorAll('.rce-wrapper')).toHaveLength(3)
        })
      })
    })

    it('renders them all if maxInitRenderedRCEs is <0', async () => {
      renderAnotherRCE(
        async () => {
          await waitFor(() => {
            expect(document.querySelectorAll('.rce-wrapper')).toHaveLength(3)
          })
        },
        {maxInitRenderedRCEs: -1},
      )
    })

    it('limits them to maxInitRenderedRCEs value', async () => {
      renderAnotherRCE(
        async () => {
          await waitFor(() => {
            expect(document.querySelectorAll('.rce-wrapper')).toHaveLength(2)
          })
        },
        {maxInitRenderedRCEs: 2},
      )
    })

    it('copes with missing IntersectionObserver', async () => {
      delete window.IntersectionObserver

      renderAnotherRCE(
        async () => {
          await waitFor(() => {
            expect(document.querySelectorAll('.rce-wrapper')).toHaveLength(3)
          })
        },
        {maxInitRenderedRCEs: 2},
      )
    })
  })

  describe('feature flags', () => {
    describe('rce_transform_loaded_content', () => {
      const encodeHTML = html => {
        const e = document.createElement('div')
        e.textContent = html
        return e.innerHTML
      }
      const exampleUrlsWithoutOrigin = [
        // basic example
        '/some/path',

        // basic example with query
        '/some/path?query=string&another=string',

        // basic example with query and hash
        '/some/path?query=string#hash',

        // This contains characters from different languages, in the path, query, and hash
        '/somewhere%20neat/%E6%9F%90%E5%A4%84/%E0%A4%95%E0%A4%B9%E0%A5%80%E0%A4%82?%D0%BA%D0%BB%D1%8E%D1%87=%D1%86%D0%B5%D0%BD%D0%B8%D1%82%D1%8C&eochair+eile=#Um%20lugar%20especial%20na%20p%C3%A1gina',
      ]

      // Note: template strings aren't used here because these values are whitespace-sensitive
      const contentWithAbsoluteUrls = exampleUrlsWithoutOrigin
        .map(it => encodeHTML(it))
        .flatMap(urlWithoutOrigin => [
          `<img src="http://example.com${urlWithoutOrigin}">`,
          `<iframe src="http://example.com${urlWithoutOrigin}"></iframe>`,
          `<img src="http://example2.com${urlWithoutOrigin}">`,
          `<iframe src="http://example2.com${urlWithoutOrigin}"></iframe>`,
        ])
        .join(``)

      const contentWithRelativeUrls = exampleUrlsWithoutOrigin
        .map(it => encodeHTML(it))
        .flatMap(urlWithoutOrigin => [
          `<img src="${urlWithoutOrigin}">`,
          `<iframe src="${urlWithoutOrigin}"></iframe>`,
          `<img src="http://example2.com${urlWithoutOrigin}">`,
          `<iframe src="http://example2.com${urlWithoutOrigin}"></iframe>`,
        ])
        .join(``)

      it('handles false', () => {
        createMountedElement({
          canvasOrigin: 'http://example.com/',
          defaultContent: contentWithAbsoluteUrls,

          features: {
            rce_transform_loaded_content: false,
          },
        })
        expect(rce.editor.getContent()).toBe(contentWithAbsoluteUrls)
      })

      it('handles true', () => {
        createMountedElement({
          canvasOrigin: 'http://example.com/',
          defaultContent: contentWithAbsoluteUrls,
          features: {
            rce_transform_loaded_content: true,
          },
        })
        expect(rce.editor.getContent()).toBe(contentWithRelativeUrls)
      })
    })
  })
})
