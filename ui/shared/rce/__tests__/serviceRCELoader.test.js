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

import $ from 'jquery'
import 'jquery-migrate'
import RCELoader from '../serviceRCELoader'
import editorUtils from '@canvas/rce/editorUtils'
import fakeENV from '@canvas/test-utils/fakeENV'
import fixtures from '@canvas/test-utils/fixtures'

describe('loadRCE', () => {
  let originalTinymce
  let originalTinyMCE

  beforeEach(() => {
    originalTinymce = window.tinymce
    originalTinyMCE = window.tinyMCE
    fakeENV.setup()
    ENV.RICH_CONTENT_APP_HOST = 'app-host'
    ENV.context_asset_string = 'courses_1'
  })

  afterEach(() => {
    window.tinymce = originalTinymce
    window.tinyMCE = originalTinyMCE
    fakeENV.teardown()
    return editorUtils.resetRCE()
  })

  it('caches the response of get_module when called', done => {
    RCELoader.RCE = null
    RCELoader.loadRCE(module => {
      expect(RCELoader.RCE).toBe(module)
      done()
    })
  })

  it('handles callbacks once module is loaded', done => {
    const spy = jest.fn()
    RCELoader.loadRCE(spy)
    RCELoader.loadRCE(RCE => {
      expect(RCE).toBe(RCELoader.RCE)
      expect(spy).toHaveBeenCalledWith(RCELoader.RCE)
      expect(spy).toHaveBeenCalledTimes(1)
      done()
    })
  })
})

describe('loadOnTarget', () => {
  let $div
  let $textarea
  let editor
  let rce
  let mockTextarea

  beforeEach(() => {
    fakeENV.setup()
    ENV.context_asset_string = 'courses_1'
    fixtures.setup()

    // Create mock textarea with required properties
    mockTextarea = {
      type: 'textarea',
      offsetWidth: 500,
      offsetHeight: 200,
      style: {},
      getAttribute: () => null,
    }

    $div = $('<div><textarea id="theTarget" name="elementName"></textarea></div>')
    $textarea = $div.find('#theTarget')

    // Mock jQuery get(0) to return our mock textarea
    $textarea.get = jest.fn().mockReturnValue(mockTextarea)
    $div.get = jest.fn().mockReturnValue($div[0])

    editor = {
      mceInstance() {
        return {
          on(_eventType, callback) {
            callback()
          },
        }
      },
      tinymceOn(_eventType, callback) {
        callback()
      },
    }
    rce = {
      renderIntoDiv: jest.fn((_target, _props, callback) => callback(editor)),
    }
    jest.spyOn(RCELoader, 'loadRCE').mockImplementation(callback => callback(rce))

    fakeENV.setup()
    ENV.RICH_CONTENT_APP_HOST = 'app-host'
    ENV.context_asset_string = 'courses_1'
  })

  afterEach(() => {
    fixtures.teardown()
    jest.restoreAllMocks()
    fakeENV.teardown()
  })

  it('uses custom target if getRenderingTarget option passed', () => {
    const customFn = () => 'someCustomTarget'
    RCELoader.loadOnTarget($textarea, {getRenderingTarget: customFn}, () => {})
    expect(rce.renderIntoDiv).toHaveBeenCalledWith(
      'someCustomTarget',
      expect.any(Object),
      expect.any(Function),
    )
  })

  it('includes onFocus in props when passed', () => {
    const onFocus = () => {}
    const opts = {onFocus}
    const props = RCELoader.createRCEProps(mockTextarea, opts)
    expect(props.onFocus).toBe(opts.onFocus)
  })

  it('yields both the original textarea and the editor to callback', done => {
    function cb(_textarea, editorInstance) {
      expect($textarea.get(0)).toBe(mockTextarea)
      expect(editorInstance).toBe(editor)
      done()
    }
    RCELoader.loadOnTarget($textarea, {}, cb)
  })

  it('ensures yielded editor has call and focus methods', done => {
    function cb(_textarea, rce_) {
      expect(typeof rce_.call).toBe('function')
      expect(typeof rce_.focus).toBe('function')
      done()
    }
    RCELoader.loadOnTarget($textarea, {}, cb)
  })

  it('populates externalToolsConfig without context_external_tool_resource_selection_url', () => {
    window.ENV = {
      RICH_CONTENT_APP_HOST: 'http://rce.host',
      RICH_CONTENT_SKIP_SIDEBAR: false,
      context_asset_string: 'course_1',
      JWT: 'jwt',
      RICH_CONTENT_CAN_UPLOAD_FILES: true,
      RICH_CONTENT_FILES_TAB_DISABLED: false,
      active_context_tab: 'files',
    }
    const props = RCELoader.createRCEProps(mockTextarea, {})
    expect(props.externalToolsConfig).toEqual({
      isA2StudentView: undefined,
      ltiIframeAllowances: undefined,
      maxMruTools: undefined,
      resourceSelectionUrlOverride: null,
    })
  })
})
