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

import ExternalToolsHelper from '@canvas/tinymce-external-tools/ExternalToolsHelper'

QUnit.module('ExternalToolsHelper:buttonConfig', {
  setup() {
    this.buttonOpts = {
      name: 'SomeName',
      id: '_SomeId',
    }
  },
  teardown() {},
})

test('makes a config as expected', function () {
  const config = ExternalToolsHelper.buttonConfig(this.buttonOpts)
  equal(config.title, 'SomeName')
  equal(config.classes, 'widget btn instructure_external_tool_button')
})

test('defaults to image if no icon class', function () {
  const btn = {
    ...this.buttonOpts,
    icon_url: 'example.com',
  }
  const config = ExternalToolsHelper.buttonConfig(btn)
  equal(config.icon, null)
  equal(config.image, 'example.com')
})

QUnit.module('ExternalToolsHelper:updateMRUList', {
  setup() {
    sinon.spy(window.console, 'log')
  },
  teardown() {
    window.localStorage.clear()
    window.console.log.restore()
  },
})

test('creates the mru list if necessary', function () {
  equal(window.localStorage.getItem('ltimru'), null)
  ExternalToolsHelper.updateMRUList(2)
  equal(window.localStorage.getItem('ltimru'), '[2]')
})

test('adds to tool to the mru list', function () {
  window.localStorage.setItem('ltimru', '[1]')
  ExternalToolsHelper.updateMRUList(2)
  equal(window.localStorage.getItem('ltimru'), '[2,1]')
})

test('limits mru list to 5 tools', function () {
  window.localStorage.setItem('ltimru', '[1,2,3,4]')
  ExternalToolsHelper.updateMRUList(5)
  equal(window.localStorage.getItem('ltimru'), '[5,1,2,3,4]')
  ExternalToolsHelper.updateMRUList(6)
  equal(window.localStorage.getItem('ltimru'), '[6,5,1,2,3]')
})

test("doesn't add the same tool twice", function () {
  window.localStorage.setItem('ltimru', '[1,2,3,4]')
  ExternalToolsHelper.updateMRUList(4)
  equal(window.localStorage.getItem('ltimru'), '[1,2,3,4]')
})

test('copes with localStorage failure updating mru list', function () {
  // localStorage in chrome is limitedto 5120k, and that seems to include the key
  window.localStorage.setItem('xyzzy', 'x'.repeat(5119 * 1024) + 'x'.repeat(1016))
  equal(window.localStorage.getItem('ltimru'), null)
  ExternalToolsHelper.updateMRUList(1)
  equal(window.localStorage.getItem('ltimru'), null)
  ok(window.console.log.calledWith('Cannot save LTI MRU list'))
})

test('corrects bad data in local storage', function () {
  window.localStorage.setItem('ltimru', 'this is not valid JSON')
  ExternalToolsHelper.updateMRUList(1)
  equal(window.localStorage.getItem('ltimru'), '[1]')
  ok(window.console.log.calledWith('Found bad LTI MRU data'))
})
