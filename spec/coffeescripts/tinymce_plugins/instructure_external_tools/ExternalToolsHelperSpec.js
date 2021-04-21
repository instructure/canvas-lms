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

import _ from 'underscore'
import ExternalToolsHelper from 'tinymce_plugins/instructure_external_tools/ExternalToolsHelper'
import $ from 'jquery'

QUnit.module('ExternalToolsHelper:buttonConfig', {
  setup() {
    this.buttonOpts = {
      name: 'SomeName',
      id: '_SomeId'
    }
  },
  teardown() {}
})

test('makes a config as expected', function() {
  const config = ExternalToolsHelper.buttonConfig(this.buttonOpts)
  equal(config.title, 'SomeName')
  equal(config.cmd, 'instructureExternalButton_SomeId')
  equal(config.classes, 'widget btn instructure_external_tool_button')
})

test('modified string to avoid mce prefix', function() {
  const btn = {
    ...this.buttonOpts,
    canvas_icon_class: 'foo-class'
  }
  const config = ExternalToolsHelper.buttonConfig(btn)
  equal(config.icon, 'hack-to-avoid-mce-prefix foo-class')
  equal(config.image, null)
})

test('defaults to image if no icon class', function() {
  const btn = {
    ...this.buttonOpts,
    icon_url: 'example.com'
  }
  const config = ExternalToolsHelper.buttonConfig(btn)
  equal(config.icon, null)
  equal(config.image, 'example.com')
})

QUnit.module('ExternalToolsHelper:clumpedButtonMapping', {
  setup() {
    this.clumpedButtons = [
      {
        id: 'ID_1',
        name: 'NAME_1',
        icon_url: '',
        canvas_icon_class: 'foo'
      },
      {
        id: 'ID_2',
        name: 'NAME_2',
        icon_url: '',
        canvas_icon_class: null
      }
    ]
    this.onClickHander = sinon.spy()
    this.fakeEditor = sinon.spy()
  },
  teardown() {}
})

test('returns a hash of markup keys and attaches click handler to value', function() {
  const mapping = ExternalToolsHelper.clumpedButtonMapping(
    this.clumpedButtons,
    this.fakeEditor,
    this.onClickHander
  )
  const imageKey = _.chain(mapping)
    .keys()
    .filter(k => k.match(/img/))
    .value()[0]
  const iconKey = _.chain(mapping)
    .keys()
    .filter(k => !k.match(/img/))
    .value()[0]
  const imageTag = imageKey.split('&nbsp')[0]
  const iconTag = iconKey.split('&nbsp')[0]
  equal($(imageTag).data('toolId'), 'ID_2')
  equal($(iconTag).data('toolId'), 'ID_1')
  ok(this.onClickHander.notCalled)
  mapping[imageKey]()
  ok(this.onClickHander.called)
})

test('returns icon markup if canvas_icon_class in button', function() {
  const mapping = ExternalToolsHelper.clumpedButtonMapping(this.clumpedButtons, () => {})
  const iconKey = _.chain(mapping)
    .keys()
    .filter(k => !k.match(/img/))
    .value()[0]
  const iconTag = iconKey.split('&nbsp')[0]
  equal($(iconTag).prop('tagName'), 'I')
})

test('returns img markup if no canvas_icon_class', function() {
  const mapping = ExternalToolsHelper.clumpedButtonMapping(this.clumpedButtons, () => {})
  const imageKey = _.chain(mapping)
    .keys()
    .filter(k => k.match(/img/))
    .value()[0]
  const imageTag = imageKey.split('&nbsp')[0]
  equal($(imageTag).prop('tagName'), 'IMG')
})

QUnit.module('ExternalToolsHelper:attachClumpedDropdown', {
  setup() {
    this.theSpy = sinon.spy()
    this.fakeTarget = {dropdownList: this.theSpy}
    this.fakeButtons = 'fb'
    this.fakeEditor = {
      on() {}
    }
  },
  teardown() {}
})

test('calls dropdownList with buttons as options', function() {
  const fakeButtons = 'fb'
  ExternalToolsHelper.attachClumpedDropdown(this.fakeTarget, fakeButtons, this.fakeEditor)
  ok(this.theSpy.calledWith({options: fakeButtons}))
})

QUnit.module('ExternalToolsHelper:updateMRUList', {
  setup() {
    sinon.spy(window.console, 'log')
  },
  teardown() {
    window.localStorage.clear()
    window.console.log.restore()
  }
})

test('creates the mru list if necessary', function() {
  equal(window.localStorage.getItem('ltimru'), null)
  ExternalToolsHelper.updateMRUList(2)
  equal(window.localStorage.getItem('ltimru'), '[2]')
})

test('adds to tool to the mru list', function() {
  window.localStorage.setItem('ltimru', '[1]')
  ExternalToolsHelper.updateMRUList(2)
  equal(window.localStorage.getItem('ltimru'), '[2,1]')
})

test('limits mru list to 5 tools', function() {
  window.localStorage.setItem('ltimru', '[1,2,3,4]')
  ExternalToolsHelper.updateMRUList(5)
  equal(window.localStorage.getItem('ltimru'), '[5,1,2,3,4]')
  ExternalToolsHelper.updateMRUList(6)
  equal(window.localStorage.getItem('ltimru'), '[6,5,1,2,3]')
})

test("doesn't add the same tool twice", function() {
  window.localStorage.setItem('ltimru', '[1,2,3,4]')
  ExternalToolsHelper.updateMRUList(4)
  equal(window.localStorage.getItem('ltimru'), '[1,2,3,4]')
})

test('copes with localStorage failure updating mru list', function() {
  // localStorage in chrome is limitedto 5120k, and that seems to include the key
  window.localStorage.setItem('xyzzy', 'x'.repeat(5119 * 1024) + 'x'.repeat(1016))
  equal(window.localStorage.getItem('ltimru'), null)
  ExternalToolsHelper.updateMRUList(1)
  equal(window.localStorage.getItem('ltimru'), null)
  ok(window.console.log.calledWith('Cannot save LTI MRU list'))
})

test('corrects bad data in local storage', function() {
  window.localStorage.setItem('ltimru', 'this is not valid JSON')
  ExternalToolsHelper.updateMRUList(1)
  equal(window.localStorage.getItem('ltimru'), '[1]')
  ok(window.console.log.calledWith('Found bad LTI MRU data'))
})
