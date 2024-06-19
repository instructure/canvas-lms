/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import {waitFor} from '@testing-library/dom'
import RichContentEditor from '../RichContentEditor'
import RCELoader from '../serviceRCELoader'
import $ from 'jquery'
import fakeENV from '@canvas/test-utils/fakeENV'
import editorUtils from '@canvas/rce/editorUtils'
import sinon from 'sinon'

const sandbox = sinon.createSandbox()

let fakeRceModule

describe('Rce Abstraction - integration', () => {
  beforeEach(() => {
    fakeENV.setup()
    ENV.RICH_CONTENT_APP_HOST = 'app-host'
    const $textarea = $(`\
    <textarea id="big_rce_text" name="context[big_rce_text]"></textarea>\
    `)
    const fixtures = $(`<div id="fixtures"></div>`)
    $('body').append(fixtures)
    $('#fixtures').empty()
    $('#fixtures').append($textarea)
    fakeRceModule = {
      props: {},
      renderIntoDiv: (renderingTarget, propsForRCE, renderCallback) => {
        $(renderingTarget).append(`<div id='fake-editor'>${propsForRCE.toString()}</div>`)
        const fakeEditor = {
          mceInstance() {
            return {
              on() {},
            }
          },
        }
        return renderCallback(fakeEditor)
      },
    }
    sandbox.stub(RCELoader, 'loadRCE').callsFake(callback => callback(fakeRceModule))
  })

  afterEach(() => {
    fakeENV.teardown()
    $('#fixtures').empty()
    editorUtils.resetRCE()
  })

  // fails in Jest, passes in QUnit
  it.skip('instatiating a remote editor', async () => {
    RichContentEditor.preloadRemoteModule()
    const target = $('#big_rce_text')
    loadNewEditor()
    await waitFor(() => RCELoader.loadRCE.callCount > 0)
    expect(target.parent().attr('id')).toBe('tinymce-parent-of-big_rce_text')
    expect(target.parent().find('#fake-editor').length).toBe(1)
  })
})

async function loadNewEditor() {
  const $target = $('#big_rce_text')
  await new Promise(resolve => {
    const tinyMCEInitOptions = {
      manageParent: true,
      tinyOptions: {
        init_instance_callback: resolve,
      },
    }
    RichContentEditor.loadNewEditor($target, tinyMCEInitOptions)
  })
}
