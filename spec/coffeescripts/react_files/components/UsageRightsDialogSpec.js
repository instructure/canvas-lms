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
import TestUtils from 'react-addons-test-utils'
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
    closeModal: () => (modalClosed = true),
    itemsToManage: [new File({thumbnail_url: 'blah', usage_rights})]
  }
  const uRD = TestUtils.renderIntoDocument(<UsageRightsDialog {...props} />)
  TestUtils.Simulate.click(uRD.refs.cancelXButton.getDOMNode())
  ok(modalClosed)
  ReactDOM.unmountComponentAtNode(uRD.getDOMNode().parentNode)
})

test('clicking canel closes the modal', () => {
  const usage_rights = {use_justification: 'choose'}
  let modalClosed = false
  const props = {
    closeModal: () => (modalClosed = true),
    itemsToManage: [new File({thumbnail_url: 'blah', usage_rights})]
  }
  const uRD = TestUtils.renderIntoDocument(<UsageRightsDialog {...props} />)
  TestUtils.Simulate.click(uRD.refs.cancelButton.getDOMNode())
  ok(modalClosed)
  ReactDOM.unmountComponentAtNode(uRD.getDOMNode().parentNode)
})

test('render the file name with multiple items', () => {
  const usage_rights = {use_justification: 'choose'}
  const props = {
    closeModal: () => (modalClosed = true),
    itemsToManage: [
      new File({thumbnail_url: 'blah', usage_rights}),
      new File({thumbnail_url: 'blah', usage_rights})
    ]
  }
  const uRD = TestUtils.renderIntoDocument(<UsageRightsDialog {...props} />)
  equal(uRD.refs.fileName.getDOMNode().innerHTML, '2 items selected', 'has correct message')
  ReactDOM.unmountComponentAtNode(uRD.getDOMNode().parentNode)
})

test('render the file name with one item', () => {
  const usage_rights = {use_justification: 'choose'}
  const file = new File({thumbnail_url: 'blah', usage_rights})
  file.displayName = () => 'cats'
  const props = {closeModal() {}, itemsToManage: [file]}
  const uRD = TestUtils.renderIntoDocument(<UsageRightsDialog {...props} />)
  equal(uRD.refs.fileName.getDOMNode().innerHTML, 'cats', 'has correct message')
  ReactDOM.unmountComponentAtNode(uRD.getDOMNode().parentNode)
})

test('render different right message', () => {
  const usage_rights = {use_justification: 'own_copyright'}
  const usage_rights2 = {use_justification: 'used_by_permission'}
  const file = new File({thumbnail_url: 'blah', usage_rights})
  file.displayName = () => 'cats'
  const file2 = new File({thumbnail_url: 'blah', usage_rights})
  file.displayName = () => 'cats2'
  const props = {
    closeModal() {},
    itemsToManage: [file, file2]
  }
  const uRD = TestUtils.renderIntoDocument(<UsageRightsDialog {...props} />)
  equal(
    uRD.refs.differentRightsMessage.props.children[1],
    'Items selected have different usage rights.',
    'displays correct message'
  )
  ReactDOM.unmountComponentAtNode(uRD.getDOMNode().parentNode)
})

test('do not render different rights message when they are the same', () => {
  const usage_rights = {use_justification: 'own_copyright', legal_copyright: ''}
  const file = new File({thumbnail_url: 'blah', usage_rights})
  file.displayName = () => 'cats'
  const file2 = new File({thumbnail_url: 'blah', usage_rights})
  file2.displayName = () => 'cats'
  const props = {
    closeModal() {},
    itemsToManage: [file, file2]
  }
  const uRD = TestUtils.renderIntoDocument(<UsageRightsDialog {...props} />)
  ok(!uRD.refs.differentRightsMessage, 'does not show the message')
  ReactDOM.unmountComponentAtNode(uRD.getDOMNode().parentNode)
})

test('render folder message for one folder', () => {
  const usage_rights = {use_justification: 'choose'}
  const folder = new Folder({usage_rights})
  folder.displayName = () => 'some folder'
  const props = {
    closeModal() {},
    itemsToManage: [folder]
  }
  const uRD = TestUtils.renderIntoDocument(<UsageRightsDialog {...props} />)
  equal(
    uRD.refs.folderBulletList.props.children[0].props.children,
    'some folder',
    'shows display name'
  )
  ReactDOM.unmountComponentAtNode(uRD.getDOMNode().parentNode)
})

test('render folder tooltip for multiple folders', () => {
  const usage_rights = {use_justification: 'choose'}
  const folder = new Folder({usage_rights})
  folder.displayName = () => 'hello'
  const props = {
    closeModal() {},
    itemsToManage: [folder, folder, folder, folder]
  }
  const uRD = TestUtils.renderIntoDocument(<UsageRightsDialog {...props} />)
  equal(
    uRD.refs.folderTooltip.getDOMNode().getAttribute('data-html-tooltip-title'),
    'hello<br />hello',
    'sets title for multple folders'
  )
  equal(uRD.refs.folderTooltip.props.children[0], 'and 2 more\u2026', 'sets count text')
  ReactDOM.unmountComponentAtNode(uRD.getDOMNode().parentNode)
})

QUnit.module('UploadProgress: Submitting')

test('validate they selected usage right', () => {
  const usage_rights = {use_justification: 'choose'}
  const file = new File({thumbnail_url: 'blah', usage_rights})
  file.displayName = () => 'hello'
  const props = {
    closeModal() {},
    itemsToManage: [file]
  }
  const uRD = TestUtils.renderIntoDocument(<UsageRightsDialog {...props} />)
  uRD.refs.usageSelection.getValues = () => ({use_justification: 'choose'})
  equal(uRD.submit(), false, 'returns false')
  ReactDOM.unmountComponentAtNode(uRD.getDOMNode().parentNode)
})
