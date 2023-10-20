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

import UsageRightsDialog from '@canvas/files/react/components/UsageRightsDialog'
import File from '@canvas/files/backbone/models/File'
import Folder from '@canvas/files/backbone/models/Folder'

QUnit.module('UsageRightsDialog', suiteHooks => {
  let $container
  let component
  let props
  let server

  suiteHooks.beforeEach(() => {
    server = sinon.createFakeServer()

    $container = document.body.appendChild(document.createElement('div'))

    const usageRights = {use_justification: 'choose'}
    props = {
      closeModal() {},
      isOpen: true,
      itemsToManage: [
        new File({
          cid: '1',
          thumbnail_url: 'http://localhost/thumbnail.png',
          usage_rights: usageRights,
        }),
      ],
    }
  })

  suiteHooks.afterEach(() => {
    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
    server.restore()
  })

  function mountComponent() {
    component = ReactDOM.render(<UsageRightsDialog {...props} />, $container)
  }

  test('displays dialog preview', () => {
    mountComponent()
    strictEqual(component.form.querySelectorAll('.DialogPreview__container').length, 1)
  })

  test('does not display dialog preview', () => {
    props.hidePreview = true
    mountComponent()
    strictEqual(component.form.querySelectorAll('.DialogPreview__container').length, 0)
  })

  test('clicking the close button closes modal', () => {
    props.closeModal = sinon.spy()
    mountComponent()
    component.cancelXButton.click()
    strictEqual(props.closeModal.callCount, 1)
  })

  test('clicking the cancel button closes the modal', () => {
    props.closeModal = sinon.spy()
    mountComponent()
    component.cancelButton.click()
    strictEqual(props.closeModal.callCount, 1)
  })

  test('renders the file name with multiple items', () => {
    const usageRights = {use_justification: 'choose'}
    props.itemsToManage = [
      new File({
        cid: '1',
        thumbnail_url: 'http://localhost/thumbnail.png',
        usage_rights: usageRights,
      }),
      new File({
        cid: '2',
        thumbnail_url: 'http://localhost/thumbnail.png',
        usage_rights: usageRights,
      }),
    ]
    mountComponent()
    equal(component.fileName.innerText.trim(), '2 items selected')
  })

  test('renders the file name with one item', () => {
    const [file] = props.itemsToManage
    file.displayName = () => 'cats'
    mountComponent()
    equal(component.fileName.innerText.trim(), 'cats')
  })

  test('renders "different rights" message', () => {
    const copyright = {use_justification: 'own_copyright'}
    const permission = {use_justification: 'used_by_permission'}
    const file1 = new File({
      cid: '1',
      thumbnail_url: 'http://localhost/thumbnail.png',
      usage_rights: copyright,
    })
    file1.displayName = () => 'cats'
    const file2 = new File({
      cid: '2',
      thumbnail_url: 'http://localhost/thumbnail.png',
      usage_rights: permission,
    })
    file2.displayName = () => 'dogs'
    props.itemsToManage = [file1, file2]
    mountComponent()
    equal(component.differentRightsMessage.innerText, 'Items selected have different usage rights.')
  })

  test('do not render different rights message when they are the same', () => {
    const usageRights = {use_justification: 'own_copyright', legal_copyright: ''}
    const file1 = new File({
      cid: '3',
      thumbnail_url: 'http://localhost/thumbnail.png',
      usage_rights: usageRights,
    })
    file1.displayName = () => 'cats'
    const file2 = new File({
      cid: '4',
      thumbnail_url: 'http://localhost/thumbnail.png',
      usage_rights: usageRights,
    })
    file2.displayName = () => 'cats'
    props.itemsToManage = [file1, file2]
    mountComponent()
    equal(typeof component.differentRightsMessage, 'undefined')
  })

  test('renders folder message for one folder', () => {
    const usageRights = {use_justification: 'choose'}
    const folder = new Folder({cid: '1', usage_rights: usageRights})
    folder.displayName = () => 'some folder'
    props.itemsToManage = [folder]
    mountComponent()
    equal(component.folderBulletList.innerText.trim(), 'some folder')
  })

  test('renders folder tooltip for multiple folders', () => {
    const usageRights = {use_justification: 'choose'}
    props.itemsToManage = []
    ;['1', '2', '3', '4'].forEach(cid => {
      const folder = new Folder({cid, usage_rights: usageRights})
      folder.displayName = () => 'hello'
      props.itemsToManage.push(folder)
    })
    mountComponent()
    equal(component.folderTooltip.getAttribute('data-html-tooltip-title'), 'hello<br />hello')
    ok(component.folderTooltip.innerText.match('and 2 more\u2026'), 'sets count text')
  })

  QUnit.module('UploadProgress: Submitting', () => {
    test('validate they selected usage right', () => {
      const usageRights = {use_justification: 'choose'}
      const file = new File({
        cid: '1',
        thumbnail_url: 'http://localhost/thumbnail.png',
        usage_rights: usageRights,
      })
      file.displayName = () => 'hello'
      props.itemsToManage = [file]
      mountComponent()
      equal(
        component.usageSelection.props.use_justification,
        'choose',
        'default use_justification is "choose"'
      )
      equal(component.submit(), false)
    })
  })
})
