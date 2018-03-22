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

import * as RceCommandShim from 'jsx/shared/rce/RceCommandShim'
import wikiSidebar from 'wikiSidebar'
import fixtures from 'helpers/fixtures'

let remoteEditor = null

QUnit.module('RceCommandShim - send', {
  setup() {
    fixtures.setup()
    this.$target = fixtures.create('<textarea />')
    this.$target.editorBox = () => ({})
    remoteEditor = {
      hidden: false,
      isHidden: () => remoteEditor.hidden,
      call: sinon.stub().returns('methodResult')
    }
  },
  teardown() {
    fixtures.teardown()
  }
})

test("just forwards through target's remoteEditor if set", function() {
  this.$target.data('remoteEditor', remoteEditor)
  equal(RceCommandShim.send(this.$target, 'methodName', 'methodArgument'), 'methodResult')
  ok(remoteEditor.call.calledWith('methodName', 'methodArgument'))
})

test('uses editorBox if remoteEditor is not set but rich_text is set', function() {
  sinon.stub(this.$target, 'editorBox').returns('methodResult')
  this.$target.data('remoteEditor', null)
  this.$target.data('rich_text', true)
  equal(RceCommandShim.send(this.$target, 'methodName', 'methodArgument'), 'methodResult')
  ok(this.$target.editorBox.calledWith('methodName', 'methodArgument'))
})

test('returns false for exists? if neither remoteEditor nor rich_text are set (e.g. load failed)', function() {
  this.$target.data('remoteEditor', null)
  this.$target.data('rich_text', null)
  equal(RceCommandShim.send(this.$target, 'exists?'), false)
})

test("returns target's val() for get_code if neither remoteEditor nor rich_text are set (e.g. load failed)", function() {
  this.$target.data('remoteEditor', null)
  this.$target.data('rich_text', null)
  this.$target.val('current raw value')
  equal(RceCommandShim.send(this.$target, 'get_code'), 'current raw value')
})

test('returns target val for get_code if editor is hidden', function() {
  remoteEditor.hidden = true
  this.$target.data('remoteEditor', remoteEditor)
  this.$target.val('current HTML value')
  equal(RceCommandShim.send(this.$target, 'get_code'), 'current HTML value')
})

test('uses the editors get_code if visible', function() {
  remoteEditor.hidden = false
  this.$target.data('remoteEditor', remoteEditor)
  equal(RceCommandShim.send(this.$target, 'get_code'), 'methodResult')
})

test('transforms create_link call for remote editor', function() {
  const url = 'http://someurl'
  const classes = 'one two'
  const previewAlt = 'alt text for preview'
  this.$target.data('remoteEditor', remoteEditor)
  RceCommandShim.send(this.$target, 'create_link', {
    url,
    classes,
    dataAttributes: {'preview-alt': previewAlt}
  })
  ok(
    remoteEditor.call.calledWithMatch('insertLink', {
      href: url,
      class: classes,
      'data-preview-alt': previewAlt
    })
  )
})

QUnit.module('RceCommandShim - focus', {
  setup() {
    fixtures.setup()
    this.$target = fixtures.create('<textarea />')
    const editor = {
      focus() {
        return {}
      }
    }
    const tinymce = {
      get: () => editor
    }
    RceCommandShim.setTinymce(tinymce)
  },
  teardown() {
    fixtures.teardown()
  }
})

test("just forwards through target's remoteEditor if set", function() {
  remoteEditor = {focus: sinon.spy()}
  this.$target.data('remoteEditor', remoteEditor)
  RceCommandShim.focus(this.$target)
  ok(remoteEditor.focus.called)
})

test('uses wikiSidebar if remoteEditor is not set but rich_text is set', function() {
  sinon.spy(wikiSidebar, 'attachToEditor')
  this.$target.data('remoteEditor', null)
  this.$target.data('rich_text', true)
  RceCommandShim.focus(this.$target)
  ok(wikiSidebar.attachToEditor.calledWith(this.$target))
  wikiSidebar.attachToEditor.restore()
})

QUnit.module('RceCommandShim - destroy', {
  setup() {
    fixtures.setup()
    this.$target = fixtures.create('<textarea />')
    this.$target.editorBox = () => ({})
  },
  teardown() {
    fixtures.teardown()
  }
})

test("forwards through target's remoteEditor if set", function() {
  remoteEditor = {destroy: sinon.spy()}
  this.$target.data('remoteEditor', remoteEditor)
  RceCommandShim.destroy(this.$target)
  ok(remoteEditor.destroy.called)
})

test("clears target's remoteEditor afterwards if set", function() {
  remoteEditor = {destroy: sinon.spy()}
  this.$target.data('remoteEditor', remoteEditor)
  RceCommandShim.destroy(this.$target)
  equal(this.$target.data('remoteEditor'), undefined)
})

test('uses editorBox if remoteEditor is not set but rich_text is set', function() {
  sinon.spy(this.$target, 'editorBox')
  this.$target.data('remoteEditor', null)
  this.$target.data('rich_text', true)
  RceCommandShim.destroy(this.$target)
  ok(this.$target.editorBox.calledWith('destroy'))
})

test('does not except if remoteEditor and editorBox are not set', function() {
  this.$target.data('remoteEditor', null)
  this.$target.data('rich_text', true)
  RceCommandShim.destroy(this.$target)
  ok(true, 'function did not throw an exception')
})
