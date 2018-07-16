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

import RichContentEditor from 'jsx/shared/rce/RichContentEditor'
import RCELoader from 'jsx/shared/rce/serviceRCELoader'
import $ from 'jquery'
import fakeENV from 'helpers/fakeENV'
import editorUtils from 'helpers/editorUtils'

QUnit.module('Rce Abstraction - integration', {
  setup() {
    fakeENV.setup()
    ENV.RICH_CONTENT_CDN_HOST = 'fakeCDN.com'
    ENV.RICH_CONTENT_APP_HOST = 'app-host'
    const $textarea = $(`\
<textarea id="big_rce_text" name="context[big_rce_text]"></textarea>\
`)
    $('#fixtures').empty()
    $('#fixtures').append($textarea)
    this.fakeRceModule = {
      props: {},
      renderIntoDiv: (renderingTarget, propsForRCE, renderCallback) => {
        $(renderingTarget).append(`<div id='fake-editor'>${propsForRCE.toString()}</div>`)
        const fakeEditor = {
          mceInstance () {
            return {
              on () { }
            }
          }
        }
        return renderCallback(fakeEditor)
      }
    }
    return sandbox.stub(RCELoader, 'loadRCE').callsFake(callback => callback(this.fakeRceModule))
  },
  teardown() {
    fakeENV.teardown()
    $('#fixtures').empty()
    return editorUtils.resetRCE()
  }
})

test('instatiating a remote editor', () => {
  ENV.RICH_CONTENT_SERVICE_ENABLED = true
  RichContentEditor.preloadRemoteModule()
  const target = $('#big_rce_text')
  RichContentEditor.loadNewEditor(target, {manageParent: true})
  equal(target.parent().attr('id'), 'tinymce-parent-of-big_rce_text')
  equal(target.parent().find('#fake-editor').length, 1)
})

test('instatiating a local editor', () => {
  ENV.RICH_CONTENT_SERVICE_ENABLED = false
  RichContentEditor.preloadRemoteModule()
  const target = $('#big_rce_text')
  RichContentEditor.loadNewEditor(target, {manageParent: true})
  equal($('#fake-editor').length, 0)
})
