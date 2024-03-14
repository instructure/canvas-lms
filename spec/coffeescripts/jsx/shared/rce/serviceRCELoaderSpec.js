/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import RCELoader from '@canvas/rce/serviceRCELoader'
import editorUtils from 'helpers/editorUtils'
import fakeENV from 'helpers/fakeENV'
import fixtures from 'helpers/fixtures'

QUnit.module('loadRCE', {
  setup() {
    this.originalTinymce = window.tinymce
    this.originalTinyMCE = window.tinyMCE
    fakeENV.setup()
    ENV.RICH_CONTENT_APP_HOST = 'app-host'
    ENV.context_asset_string = 'courses_1'
  },
  teardown() {
    // until canvas and canvas-rce are on the same version, restore globals to
    // the canvas version of tinymce
    window.tinymce = this.originalTinymce
    window.tinyMCE = this.originalTinyMCE
    fakeENV.teardown()
    return editorUtils.resetRCE()
  },
})

// loading RCE
test('caches the response of get_module when called', assert => {
  const done = assert.async()
  RCELoader.RCE = null
  return RCELoader.loadRCE(module => {
    equal(RCELoader.RCE, module)
    done()
  })
})

test('handles callbacks once module is loaded', assert => {
  const done = assert.async()

  const spy = sinon.spy()
  RCELoader.loadRCE(spy)
  return RCELoader.loadRCE(RCE => {
    equal(RCE, RCELoader.RCE)
    ok(spy.calledOnceWith(RCELoader.RCE))
    done()
  })
})

QUnit.module('loadOnTarget', {
  setup() {
    fakeENV.setup()
    ENV.context_asset_string = 'courses_1'
    fixtures.setup()
    this.$div = fixtures.create(
      '<div><textarea id="theTarget" name="elementName"></textarea></div>'
    )
    this.$textarea = fixtures.find('#theTarget')
    this.editor = {
      mceInstance() {
        return {
          on(eventType, callback) {
            callback()
          },
        }
      },
      tinymceOn(eventType, callback) {
        callback()
      },
    }
    this.rce = {renderIntoDiv: sinon.stub().callsArgWith(2, this.editor)}
    sinon.stub(RCELoader, 'loadRCE').callsArgWith(0, this.rce)
    fakeENV.setup()
    ENV.RICH_CONTENT_APP_HOST = 'app-host'
    ENV.context_asset_string = 'courses_1'
  },
  teardown() {
    fixtures.teardown()
    RCELoader.loadRCE.restore()
    fakeENV.teardown()
  },
})

// target finding

test('finds a target textarea if a textarea is passed in', function () {
  equal(RCELoader.getTargetTextarea(this.$textarea), this.$textarea.get(0))
})

test('finds a target textarea if a normal div is passed in', function () {
  equal(RCELoader.getTargetTextarea(this.$div), this.$textarea.get(0))
})

test('returns the textareas parent as the renderingTarget when no custom function given', function () {
  equal(RCELoader.getRenderingTarget(this.$textarea.get(0)), this.$div.get(0))
})

test('returned parent has class `ic-RichContentEditor`', function () {
  const target = RCELoader.getRenderingTarget(this.$textarea.get(0))
  ok($(target).hasClass('ic-RichContentEditor'))
})

test('uses a custom get target function if given', function () {
  const customFn = () => 'someCustomTarget'
  RCELoader.loadOnTarget(this.$textarea, {getRenderingTarget: customFn}, () => {})
  ok(this.rce.renderIntoDiv.calledWith('someCustomTarget'))
})
// propsForRCE construction

test('extracts content from the target', function () {
  this.$textarea.val('some text here')
  const opts = {defaultContent: 'default text'}
  const props = RCELoader.createRCEProps(this.$textarea.get(0), opts)
  equal(props.defaultContent, 'some text here')
})

test('falls back to defaultContent if target has no content', function () {
  const opts = {defaultContent: 'default text'}
  const props = RCELoader.createRCEProps(this.$textarea.get(0), opts)
  equal(props.defaultContent, 'default text')
})

test('passes the textarea height into tinyOptions', () => {
  const taHeight = '123'
  const textarea = {offsetHeight: taHeight}
  const opts = {defaultContent: 'default text'}
  RCELoader.createRCEProps(textarea, opts)
  equal(opts.tinyOptions.height, taHeight)
})

test('adds the elements name attribute to mirroredAttrs', function () {
  const opts = {defaultContent: 'default text'}
  const props = RCELoader.createRCEProps(this.$textarea.get(0), opts)
  equal(props.mirroredAttrs.name, 'elementName')
})

test('adds onFocus to props', function () {
  const opts = {
    onFocus() {},
  }
  const props = RCELoader.createRCEProps(this.$textarea.get(0), opts)
  equal(props.onFocus, opts.onFocus)
})

test('renders with rce', function () {
  RCELoader.loadOnTarget(this.$div, {}, () => {})
  ok(this.rce.renderIntoDiv.calledWith(this.$div.get(0)))
})

test('yields editor to callback,', function (assert) {
  const done = assert.async()
  const cb = (textarea, rce) => {
    equal(textarea, this.$textarea.get(0))
    equal(rce, this.editor)
    done()
  }
  RCELoader.loadOnTarget(this.$div, {}, cb)
})

test('ensures yielded editor has call and focus methods', function (assert) {
  const done = assert.async()
  const cb = (textarea, rce) => {
    equal(typeof rce.call, 'function')
    equal(typeof rce.focus, 'function')
    done()
  }
  RCELoader.loadOnTarget(this.$div, {}, cb)
})

test('populates externalToolsConfig without context_external_tool_resource_selection_url', () => {
  window.ENV = {
    LTI_LAUNCH_FRAME_ALLOWANCES: ['test allow'],
    a2_student_view: true,
    MAX_MRU_LTI_TOOLS: 892,
  }

  deepEqual(RCELoader.createRCEProps({}, {}).externalToolsConfig, {
    ltiIframeAllowances: ['test allow'],
    isA2StudentView: true,
    maxMruTools: 892,
    resourceSelectionUrlOverride: null,
  })
})

test('populates externalToolsConfig with context_external_tool_resource_selection_url', () => {
  window.ENV = {
    LTI_LAUNCH_FRAME_ALLOWANCES: ['test allow'],
    a2_student_view: true,
    MAX_MRU_LTI_TOOLS: 892,
  }

  const a = document.createElement('a')
  try {
    a.id = 'context_external_tool_resource_selection_url'
    a.href = 'http://www.example.com'
    document.body.appendChild(a)

    deepEqual(RCELoader.createRCEProps({}, {}).externalToolsConfig, {
      ltiIframeAllowances: ['test allow'],
      isA2StudentView: true,
      maxMruTools: 892,
      resourceSelectionUrlOverride: 'http://www.example.com',
    })
  } finally {
    a.remove()
  }
})
