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
import RCELoader from 'jsx/shared/rce/serviceRCELoader'
import * as jwt from 'jsx/shared/jwt'
import editorUtils from 'helpers/editorUtils'
import fakeENV from 'helpers/fakeENV'
import fixtures from 'helpers/fixtures'

QUnit.module('loadRCE', {
  setup() {
    this.originalTinymce = window.tinymce
    this.originalTinyMCE = window.tinyMCE
    fakeENV.setup()
    ENV.RICH_CONTENT_APP_HOST = 'app-host'
  },
  teardown() {
    // until canvas and canvas-rce are on the same version, restore globals to
    // the canvas version of tinymce
    window.tinymce = this.originalTinymce
    window.tinyMCE = this.originalTinyMCE
    fakeENV.teardown()
    return editorUtils.resetRCE()
  }
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

test('loads event listeners on first load', function(assert) {
  const done = assert.async()
  this.stub(RCELoader, 'loadEventListeners')
  RCELoader.RCE = null
  return RCELoader.loadRCE(() => {
    ok(RCELoader.loadEventListeners.called)
    done()
  })
})

test('does not load event listeners once loaded', function(assert) {
  const done = assert.async()
  this.stub(RCELoader, 'loadEventListeners')
  RCELoader.RCE = {}
  return RCELoader.loadRCE(() => {
    ok(!RCELoader.loadEventListeners.called)
    done()
  })
})

test('handles callbacks once module is loaded', assert => {
  const done = assert.async()
  RCELoader.loadRCE(() => {})
  return RCELoader.loadRCE(module => {
    ok(module.renderIntoDiv)
    done()
  })
})

QUnit.module('loadOnTarget', {
  setup() {
    fixtures.setup()
    this.$div = fixtures.create('<div><textarea id="theTarget" name="elementName" /></div>')
    this.$textarea = fixtures.find('#theTarget')
    this.editor = {}
    this.rce = {renderIntoDiv: sinon.stub().callsArgWith(2, this.editor)}
    sinon.stub(RCELoader, 'loadRCE').callsArgWith(0, this.rce)
  },
  teardown() {
    fixtures.teardown()
    RCELoader.loadRCE.restore()
  }
})

// target finding

test('finds a target textarea if a textarea is passed in', function() {
  equal(RCELoader.getTargetTextarea(this.$textarea), this.$textarea.get(0))
})

test('finds a target textarea if a normal div is passed in', function() {
  equal(RCELoader.getTargetTextarea(this.$div), this.$textarea.get(0))
})

test('returns the textareas parent as the renderingTarget when no custom function given', function() {
  equal(RCELoader.getRenderingTarget(this.$textarea.get(0)), this.$div.get(0))
})

test('returned parent has class `ic-RichContentEditor`', function() {
  const target = RCELoader.getRenderingTarget(this.$textarea.get(0))
  ok($(target).hasClass('ic-RichContentEditor'))
})

test('uses a custom get target function if given', function() {
  const customFn = () => 'someCustomTarget'
  RCELoader.loadOnTarget(this.$textarea, {getRenderingTarget: customFn}, () => {})
  ok(this.rce.renderIntoDiv.calledWith('someCustomTarget'))
})
// propsForRCE construction

test('extracts content from the target', function() {
  this.$textarea.val('some text here')
  const opts = {defaultContent: 'default text'}
  const props = RCELoader.createRCEProps(this.$textarea.get(0), opts)
  equal(props.defaultContent, 'some text here')
})

test('falls back to defaultContent if target has no content', function() {
  const opts = {defaultContent: 'default text'}
  const props = RCELoader.createRCEProps(this.$textarea.get(0), opts)
  equal(props.defaultContent, 'default text')
})

test('passes the textarea height into tinyOptions', () => {
  const taHeight = '123'
  const textarea = {offsetHeight: taHeight}
  const opts = {defaultContent: 'default text'}
  const props = RCELoader.createRCEProps(textarea, opts)
  equal(opts.tinyOptions.height, taHeight)
})

test('adds the elements name attribute to mirroredAttrs', function() {
  const opts = {defaultContent: 'default text'}
  const props = RCELoader.createRCEProps(this.$textarea.get(0), opts)
  equal(props.mirroredAttrs.name, 'elementName')
})

test('adds onFocus to props', function() {
  const opts = {
    onFocus() {}
  }
  const props = RCELoader.createRCEProps(this.$textarea.get(0), opts)
  equal(props.onFocus, opts.onFocus)
})

test('renders with rce', function() {
  RCELoader.loadOnTarget(this.$div, {}, () => {})
  ok(this.rce.renderIntoDiv.calledWith(this.$div.get(0)))
})

test('yields editor to callback', function() {
  const cb = sinon.spy()
  RCELoader.loadOnTarget(this.$div, {}, cb)
  ok(cb.calledWith(this.$textarea.get(0), this.editor))
})

test('ensures yielded editor has call and focus methods', function() {
  const cb = sinon.spy()
  RCELoader.loadOnTarget(this.$div, {}, cb)
  equal(typeof this.editor.call, 'function')
  equal(typeof this.editor.focus, 'function')
})

QUnit.module('loadSidebarOnTarget', {
  setup() {
    fakeENV.setup()
    ENV.RICH_CONTENT_APP_HOST = 'http://rce.host'
    ENV.RICH_CONTENT_CAN_UPLOAD_FILES = true
    ENV.context_asset_string = 'courses_1'
    fixtures.setup()
    this.$div = fixtures.create('<div />')
    this.sidebar = {}
    this.rce = {renderSidebarIntoDiv: sinon.stub().callsArgWith(2, this.sidebar)}
    sinon.stub(RCELoader, 'loadRCE').callsArgWith(0, this.rce)
    this.refreshToken = sinon.spy()
    this.stub(jwt, 'refreshFn').returns(this.refreshToken)
  },
  teardown() {
    fakeENV.teardown()
    fixtures.teardown()
    RCELoader.loadRCE.restore()
  }
})

test('passes host and context from ENV as props to sidebar', function() {
  const cb = sinon.spy()
  RCELoader.loadSidebarOnTarget(this.$div, cb)
  ok(this.rce.renderSidebarIntoDiv.called)
  const props = this.rce.renderSidebarIntoDiv.args[0][1]
  equal(props.host, 'http://rce.host')
  equal(props.contextType, 'courses')
  equal(props.contextId, '1')
})

test('yields sidebar to callback', function() {
  const cb = sinon.spy()
  RCELoader.loadSidebarOnTarget(this.$div, cb)
  ok(cb.calledWith(this.sidebar))
})

test('ensures yielded sidebar has show and hide methods', function() {
  const cb = sinon.spy()
  RCELoader.loadSidebarOnTarget(this.$div, cb)
  equal(typeof this.sidebar.show, 'function')
  equal(typeof this.sidebar.hide, 'function')
})

test('provides a callback for loading a new jwt', function() {
  const cb = sinon.spy()
  RCELoader.loadSidebarOnTarget(this.$div, cb)
  ok(this.rce.renderSidebarIntoDiv.called)
  const props = this.rce.renderSidebarIntoDiv.args[0][1]
  ok(jwt.refreshFn.calledWith(props.jwt))
  equal(props.refreshToken, this.refreshToken)
})

test('passes brand config json url', function() {
  ENV.active_brand_config_json_url = {}
  RCELoader.loadSidebarOnTarget(this.$div, () => {})
  const props = this.rce.renderSidebarIntoDiv.args[0][1]
  equal(props.themeUrl, ENV.active_brand_config_json_url)
})
