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
import * as RceCommandShim from 'jsx/shared/rce/RceCommandShim'
import RCELoader from 'jsx/shared/rce/serviceRCELoader'
import Sidebar from 'jsx/shared/rce/Sidebar'
import fakeENV from 'helpers/fakeENV'
import editorUtils from 'helpers/editorUtils'
import fixtures from 'helpers/fixtures'
import 'tinymce.editor_box'

QUnit.module('RichContentEditor - helper function:')

test('ensureID gives the element an id when it is missing', () => {
  const $el = $('<div/>')
  RichContentEditor.ensureID($el)
  ok($el.attr('id') != null)
})

test('ensureID gives the element an id when it is blank', () => {
  const $el = $('<div id/>')
  RichContentEditor.ensureID($el)
  ok($el.attr('id') !== '')
})

test("ensureID doesn't overwrite an existing id", () => {
  const $el = $('<div id="test"/>')
  RichContentEditor.ensureID($el)
  ok($el.attr('id') === 'test')
})

test('freshNode returns the given element if the id is missing', () => {
  const $el = $('<div/>')
  const $fresh = RichContentEditor.freshNode($el)
  equal($el, $fresh)
})

test('freshNode returns the given element if the id is blank', () => {
  const $el = $('<div id/>')
  const $fresh = RichContentEditor.freshNode($el)
  equal($el, $fresh)
})

test("freshNode returns the given element if it's not on the dom", () => {
  const $el = $('<div id="test"/>')
  const $fresh = RichContentEditor.freshNode($el)
  equal($el, $fresh)
})

QUnit.module('RichContentEditor - preloading', {
  setup() {
    fakeENV.setup()
    this.stub(RCELoader, 'preload')
  },
  teardown() {
    fakeENV.teardown()
    editorUtils.resetRCE()
  }
})

test('loads via RCELoader.preload when service enabled', () => {
  ENV.RICH_CONTENT_SERVICE_ENABLED = true
  ENV.RICH_CONTENT_APP_HOST = 'app-host'
  RichContentEditor.preloadRemoteModule()
  ok(RCELoader.preload.called)
})

test('does nothing when service disabled', () => {
  ENV.RICH_CONTENT_SERVICE_ENABLED = undefined
  RichContentEditor.preloadRemoteModule()
  ok(RCELoader.preload.notCalled)
})

QUnit.module('RichContentEditor - loading editor', {
  setup() {
    fakeENV.setup()
    ENV.RICH_CONTENT_SERVICE_ENABLED = true
    ENV.RICH_CONTENT_APP_HOST = 'http://fakehost.com'
    fixtures.setup()
    this.$target = fixtures.create('<textarea id="myEditor" />')
    sinon.stub(RCELoader, 'loadOnTarget')
    this.stub(Sidebar, 'show')
  },
  teardown() {
    fakeENV.teardown()
    fixtures.teardown()
    RCELoader.loadOnTarget.restore()
    editorUtils.resetRCE()
  }
})

test('calls RCELoader.loadOnTarget with target and options', function() {
  sinon
    .stub(RichContentEditor, 'freshNode')
    .withArgs(this.$target)
    .returns(this.$target)
  const options = {}
  RichContentEditor.loadNewEditor(this.$target, options)
  ok(RCELoader.loadOnTarget.calledWith(this.$target, sinon.match(options)))
  RichContentEditor.freshNode.restore()
})

test('calls editorBox and set_code when feature flag off', function(assert) {
  const done = assert.async()
  ENV.RICH_CONTENT_SERVICE_ENABLED = false
  sinon.stub(this.$target, 'editorBox')
  this.$target.editorBox.onCall(0).returns(this.$target)
  return RichContentEditor.loadNewEditor(this.$target, {defaultContent: 'content'}, () => {
    ok(this.$target.editorBox.calledTwice, 'called twice')
    ok(this.$target.editorBox.firstCall.calledWith(), 'first called with nothing')
    ok(this.$target.editorBox.secondCall.calledWith('set_code', 'content'))
    done()
  })
})

test('skips instantiation when called with empty target', () => {
  RichContentEditor.loadNewEditor($('#fixtures .invalidTarget'), {})
  ok(RCELoader.loadOnTarget.notCalled)
})

test('with focus:true calls focus on RceCommandShim after load', function(assert) {
  const done = assert.async()
  ENV.RICH_CONTENT_SERVICE_ENABLED = false
  sinon.stub(RceCommandShim, 'focus')
  return RichContentEditor.loadNewEditor(this.$target, {focus: true}, () => {
    ok(RceCommandShim.focus.calledWith(this.$target))
    RceCommandShim.focus.restore()
    done()
  })
})

test('with focus:true tries to show sidebar', function(assert) {
  const done = assert.async()
  // false so we don't have to stub out RCELoader.loadOnTarget
  ENV.RICH_CONTENT_SERVICE_ENABLED = false
  RichContentEditor.initSidebar()
  return RichContentEditor.loadNewEditor(this.$target, {focus: true}, () => {
    ok(Sidebar.show.called)
    done()
  })
})

test('hides resize handle when called', function() {
  const $resize = fixtures.create('<div class="mce-resizehandle"></div>')
  RichContentEditor.loadNewEditor(this.$target, {})
  equal($resize.attr('aria-hidden'), 'true')
})

test('onFocus calls options.onFocus if exists', function() {
  const options = {onFocus: this.spy()}
  RichContentEditor.loadNewEditor(this.$target, options)
  const {onFocus} = RCELoader.loadOnTarget.firstCall.args[1]
  const editor = {}
  onFocus(editor)
  ok(options.onFocus.calledWith(editor))
})

QUnit.module('RichContentEditor - callOnRCE', {
  setup() {
    fakeENV.setup()
    fixtures.setup()
    this.$target = fixtures.create('<textarea id="myEditor" />')
    sinon.stub(RceCommandShim, 'send').returns('methodResult')
  },
  teardown() {
    fakeENV.teardown()
    fixtures.teardown()
    RceCommandShim.send.restore()
    editorUtils.resetRCE()
  }
})

test('proxies to RceCommandShim', function() {
  equal(RichContentEditor.callOnRCE(this.$target, 'methodName', 'methodArg'), 'methodResult')
  ok(RceCommandShim.send.calledWith(this.$target, 'methodName', 'methodArg'))
})

test('with flag enabled freshens node before passing to RceCommandShim', function() {
  ENV.RICH_CONTENT_SERVICE_ENABLED = true
  const $freshTarget = $(this.$target) // new jquery obj of same node
  sinon
    .stub(RichContentEditor, 'freshNode')
    .withArgs(this.$target)
    .returns($freshTarget)
  equal(RichContentEditor.callOnRCE(this.$target, 'methodName', 'methodArg'), 'methodResult')
  ok(RceCommandShim.send.calledWith($freshTarget, 'methodName', 'methodArg'))
  RichContentEditor.freshNode.restore()
})

QUnit.module('RichContentEditor - destroyRCE', {
  setup() {
    fakeENV.setup()
    ENV.RICH_CONTENT_SERVICE_ENABLED = false
    fixtures.setup()
    this.$target = fixtures.create('<textarea id="myEditor" />')
  },
  teardown() {
    fakeENV.teardown()
    fixtures.teardown()
    editorUtils.resetRCE()
  }
})

test('proxies destroy to RceCommandShim', function() {
  sinon.stub(RceCommandShim, 'destroy')
  RichContentEditor.destroyRCE(this.$target)
  ok(RceCommandShim.destroy.calledWith(this.$target))
  RceCommandShim.destroy.restore()
})

test('tries to hide the sidebar', function() {
  RichContentEditor.initSidebar()
  sinon.spy(Sidebar, 'hide')
  RichContentEditor.destroyRCE(this.$target)
  ok(Sidebar.hide.called)
  Sidebar.hide.restore()
})

QUnit.module('RichContentEditor - clicking into editor (editor_box_focus)', {
  setup() {
    fakeENV.setup()
    ENV.RICH_CONTENT_SERVICE_ENABLED = false
    fixtures.setup()
    this.$target = fixtures.create('<textarea id="myEditor" />')
    RichContentEditor.loadNewEditor(this.$target)
    sinon.stub(RceCommandShim, 'focus')
  },
  teardown() {
    fakeENV.teardown()
    fixtures.teardown()
    editorUtils.resetRCE()
    RceCommandShim.focus.restore()
  }
})

test('on target causes target to focus', function() {
  // would be nicer to test based on actual click causing this trigger, but
  // not sure how to do that. for now this will do
  this.$target.triggerHandler('editor_box_focus')
  ok(RceCommandShim.focus.calledWith(this.$target))
})

test('with multiple targets only focuses triggered target', function() {
  // would be nicer to test based on actual click causing this trigger, but
  // not sure how to do that. for now this will do
  const $otherTarget = fixtures.create('<textarea id="otherEditor" />')
  RichContentEditor.loadNewEditor($otherTarget)
  $otherTarget.triggerHandler('editor_box_focus')
  ok(RceCommandShim.focus.calledOnce)
  ok(RceCommandShim.focus.calledWith($otherTarget))
  ok(RceCommandShim.focus.neverCalledWith(this.$target))
})
