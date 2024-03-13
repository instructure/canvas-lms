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

import $ from 'jquery'
import 'jquery-migrate'
import RichContentEditor from '@canvas/rce/RichContentEditor'
import * as RceCommandShim from '@canvas/rce-command-shim'
import RCELoader from '@canvas/rce/serviceRCELoader'
import Sidebar from '@canvas/rce/Sidebar'
import fakeENV from 'helpers/fakeENV'
import editorUtils from 'helpers/editorUtils'
import fixtures from 'helpers/fixtures'

QUnit.module('RichContentEditor - helper function:')

test('ensureID gives the element an id when it is missing', () => {
  const $el = $('<div/>')
  RichContentEditor.ensureID($el)
  notEqual($el.attr('id'), null)
})

test('ensureID gives the element an id when it is blank', () => {
  const $el = $('<div id/>')
  RichContentEditor.ensureID($el)
  notEqual($el.attr('id'), '')
})

test("ensureID doesn't overwrite an existing id", () => {
  const $el = $('<div id="test"/>')
  RichContentEditor.ensureID($el)
  equal($el.attr('id'), 'test')
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

test("node2jquery returns the given element is null'", () => {
  const $el = null
  const $empty_node = $()
  const $fresh = RichContentEditor.node2jquery($el)
  deepEqual($empty_node, $fresh)
})

QUnit.module('RichContentEditor - preloading', {
  setup() {
    fakeENV.setup()
    sandbox.stub(RCELoader, 'preload')
  },
  teardown() {
    fakeENV.teardown()
    editorUtils.resetRCE()
  },
})

test('loads via RCELoader.preload when service enabled', () => {
  ENV.RICH_CONTENT_APP_HOST = 'app-host'
  RichContentEditor.preloadRemoteModule()
  ok(RCELoader.preload.called)
})

QUnit.module('RichContentEditor - loading editor', {
  setup() {
    fakeENV.setup()
    ENV.RICH_CONTENT_APP_HOST = 'http://fakehost.com'
    fixtures.setup()
    this.$target = fixtures.create('<textarea id="myEditor" />')
    sinon.stub(RCELoader, 'loadOnTarget')
    sandbox.stub(Sidebar, 'show')
  },
  teardown() {
    fakeENV.teardown()
    fixtures.teardown()
    RCELoader.loadOnTarget.restore()
    editorUtils.resetRCE()
  },
})
test('calls RCELoader.loadOnTarget with target and options', function () {
  sinon.stub(RichContentEditor, 'freshNode').withArgs(this.$target).returns(this.$target)
  const options = {}
  RichContentEditor.loadNewEditor(this.$target, options)
  ok(RCELoader.loadOnTarget.calledWith(this.$target, sinon.match(options)))
  RichContentEditor.freshNode.restore()
})

test('skips instantiation when called with empty target', () => {
  RichContentEditor.loadNewEditor($('#fixtures .invalidTarget'), {})
  ok(RCELoader.loadOnTarget.notCalled)
})

test('hides resize handle when called', function () {
  const $resize = fixtures.create('<div class="mce-resizehandle"></div>')
  RichContentEditor.loadNewEditor(this.$target, {})
  equal($resize.attr('aria-hidden'), 'true')
})

test('onFocus calls options.onFocus if exists', function () {
  const options = {onFocus: sinon.spy()}
  RichContentEditor.loadNewEditor(this.$target, options)
  const {onFocus} = RCELoader.loadOnTarget.firstCall.args[1]
  const editor = {}
  onFocus(editor)
  ok(options.onFocus.calledWith(editor))
})

test('throws error or establishParentNode escapes targetId to prevent xss', () => {
  let errorThrown = false

  try {
    const $target = fixtures.create(
      '<div class="reply-textarea" id="x\'><img src=x onerror=\'alert(`${document.domain}:${document.cookie}`)\' />">XSS</div>' // eslint-disable-line no-template-curly-in-string
    )
    RichContentEditor.loadNewEditor($target, {manageParent: true})
  } catch (error) {
    errorThrown = true
  }

  if (errorThrown) {
    equal(errorThrown, true)
  } else {
    const successfulXSSImg = $('img')
    equal(successfulXSSImg.length, 0)
  }
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
  },
})

test('with flag enabled freshens node before passing to RceCommandShim', function () {
  const $freshTarget = $(this.$target) // new jquery obj of same node
  sinon.stub(RichContentEditor, 'freshNode').withArgs(this.$target).returns($freshTarget)
  equal(RichContentEditor.callOnRCE(this.$target, 'methodName', 'methodArg'), 'methodResult')
  ok(RceCommandShim.send.calledWith($freshTarget, 'methodName', 'methodArg'))
  RichContentEditor.freshNode.restore()
})
