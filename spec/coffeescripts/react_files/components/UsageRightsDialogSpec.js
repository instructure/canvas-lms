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

import React from 'react'
import ReactDOM from 'react-dom'
import TestUtils from 'react-dom/test-utils'
import $ from 'jquery'
import UsageRightsDialog from 'jsx/files/UsageRightsDialog'
import File from 'compiled/models/File'
import Folder from 'compiled/models/Folder'

QUnit.module('UsageRightsDialog', {
  teardown() {
    $('#ui-datepicker-div').empty()
    $('.ui-dialog').remove()
    $('div[id^=ui-id-]').remove()
  }
})

test('clicking cancelXButton closes modal', () => {
  const usage_rights = {use_justification: 'choose'}
  let modalClosed = false
  const props = {
    isOpen: true,
    closeModal: () => (modalClosed = true),
    itemsToManage: [new File({thumbnail_url: 'blah', usage_rights})]
  }
  const uRD = TestUtils.renderIntoDocument(<UsageRightsDialog {...props} />)
  TestUtils.Simulate.click(uRD.cancelXButton)
  ok(modalClosed)
})

test('clicking canel closes the modal', () => {
  const usage_rights = {use_justification: 'choose'}
  let modalClosed = false
  const props = {
    isOpen: true,
    closeModal: () => (modalClosed = true),
    itemsToManage: [new File({thumbnail_url: 'blah', usage_rights})]
  }
  const uRD = TestUtils.renderIntoDocument(<UsageRightsDialog {...props} />)
  TestUtils.Simulate.click(uRD.cancelButton)
  ok(modalClosed)
})

test('render the file name with multiple items', () => {
  const usage_rights = {use_justification: 'choose'}
  const props = {
    isOpen: true,
    closeModal: () => {},
    itemsToManage: [
      new File({thumbnail_url: 'blah', usage_rights}),
      new File({thumbnail_url: 'blah', usage_rights})
    ]
  }
  const uRD = TestUtils.renderIntoDocument(<UsageRightsDialog {...props} />)
  equal(uRD.fileName.innerText.trim(), '2 items selected', 'has correct message')
})

test('render the file name with one item', () => {
  const usage_rights = {use_justification: 'choose'}
  const file = new File({thumbnail_url: 'blah', usage_rights})
  file.displayName = () => 'cats'
  const props = {isOpen: true, closeModal() {}, itemsToManage: [file]}
  const uRD = TestUtils.renderIntoDocument(<UsageRightsDialog {...props} />)
  equal(uRD.fileName.innerText.trim(), 'cats', 'has correct message')
})

test('render different right message', () => {
  const usage_rights = {use_justification: 'own_copyright'}
  const usage_rights2 = {use_justification: 'used_by_permission'}
  const file = new File({thumbnail_url: 'blah', cid: '1', usage_rights})
  file.displayName = () => 'cats'
  const file2 = new File({thumbnail_url: 'blah', cid: '2', usage_rights})
  file.displayName = () => 'cats2'
  const props = {
    isOpen: true,
    closeModal() {},
    itemsToManage: [file, file2]
  }
  const uRD = TestUtils.renderIntoDocument(<UsageRightsDialog {...props} />)
  equal(
    uRD.differentRightsMessage.innerText,
    'Items selected have different usage rights.',
    'displays correct message'
  )
})

test('do not render different rights message when they are the same', () => {
  const usage_rights = {use_justification: 'own_copyright', legal_copyright: ''}
  const file = new File({thumbnail_url: 'blah', cid: '3', usage_rights})
  file.displayName = () => 'cats'
  const file2 = new File({thumbnail_url: 'blah', cid: '4', usage_rights})
  file2.displayName = () => 'cats'
  const props = {
    isOpen: true,
    closeModal() {},
    itemsToManage: [file, file2]
  }
  const uRD = TestUtils.renderIntoDocument(<UsageRightsDialog {...props} />)
  ok(!uRD.differentRightsMessage, 'does not show the message')
})

test('render folder message for one folder', () => {
  const usage_rights = {use_justification: 'choose'}
  const folder = new Folder({cid: 1, usage_rights})
  folder.displayName = () => 'some folder'
  const props = {
    isOpen: true,
    closeModal() {},
    itemsToManage: [folder]
  }
  const uRD = TestUtils.renderIntoDocument(<UsageRightsDialog {...props} />)
  equal(uRD.folderBulletList.innerText.trim(), 'some folder', 'shows display name')
})

test('render folder tooltip for multiple folders', () => {
  const usage_rights = {use_justification: 'choose'}
  const folder = new Folder({usage_rights})
  folder.displayName = () => 'hello'
  const props = {
    isOpen: true,
    closeModal() {},
    itemsToManage: [folder, folder, folder, folder]
  }
  const uRD = TestUtils.renderIntoDocument(<UsageRightsDialog {...props} />)
  equal(
    uRD.folderTooltip.getAttribute('data-html-tooltip-title'),
    'hello<br />hello',
    'sets title for multple folders'
  )
  ok(uRD.folderTooltip.innerText.match('and 2 more\u2026'), 'sets count text')
})

QUnit.module('UploadProgress: Submitting')

test('validate they selected usage right', () => {
  const usage_rights = {use_justification: 'choose'}
  const file = new File({thumbnail_url: 'blah', usage_rights})
  file.displayName = () => 'hello'
  const props = {
    isOpen: true,
    closeModal() {},
    itemsToManage: [file]
  }
  const uRD = TestUtils.renderIntoDocument(<UsageRightsDialog {...props} />)
  equal(
    uRD.usageSelection.props.use_justification,
    'choose',
    'default use_justification is "choose"'
  )
  equal(uRD.submit(), false, 'returns false')
})
