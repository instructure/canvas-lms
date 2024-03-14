/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

/* eslint-disable jsx-a11y/anchor-is-valid */

import React from 'react'
import TestUtils from 'react-dom/test-utils'
import {fireEvent, render} from '@testing-library/react'
import {screen} from '@testing-library/dom'
import fetchMock from 'fetch-mock'
import $ from 'jquery'
import ItemCog from '../ItemCog'
import File from '@canvas/files/backbone/models/File'
import Folder from '@canvas/files/backbone/models/Folder'

const {Simulate} = TestUtils

const readOnlyConfig = {
  download: true,
  editName: false,
  restrictedDialog: false,
  move: false,
  deleteLink: false,
}

const manageFilesConfig = {
  download: true,
  editName: true,
  usageRights: true,
  move: true,
  deleteLink: true,
}

const buttonsEnabled = config => {
  let valid = true
  for (const prop in config) {
    const button = screen.queryByTestId(prop) || false
    if ((config[prop] && !!button) || (!config[prop] && !button)) {
      continue
    } else {
      valid = false
    }
  }
  return valid
}

const sampleProps = (
  canAddFiles = false,
  canEditFiles = false,
  canDeleteFiles = false,
  canRestrictFiles = false
) => ({
  externalToolsForContext: [],
  model: new Folder({id: 999}),
  modalOptions: {
    closeModal() {},
    openModal() {},
  },
  startEditingName() {},
  userCanAddFilesForContext: canAddFiles,
  userCanEditFilesForContext: canEditFiles,
  userCanDeleteFilesForContext: canDeleteFiles,
  userCanRestrictFilesForContext: canRestrictFiles,
  usageRightsRequiredForContext: true,
})

function renderCog(props) {
  return render(<ItemCog {...props} />, {container: document.getElementById('fixtures')})
}

describe('ItemCog', () => {
  let windowConfirm
  beforeEach(() => {
    windowConfirm = window.confirm
    window.confirm = jest.fn().mockReturnValue(true)
    window.ENV.context_asset_string = 'course_101'
    const fixtures = document.createElement('div')
    fixtures.id = 'fixtures'
    document.body.appendChild(fixtures)
  })

  afterEach(() => {
    window.confirm = windowConfirm
  })

  it('deletes model when delete link is pressed', () => {
    const ajaxSpy = jest.spyOn($, 'ajax')
    renderCog(sampleProps(true, true, true))
    fireEvent.click(document.querySelector('[data-testid="deleteLink"]'))
    expect(window.confirm).toHaveBeenCalledTimes(1)
    expect(ajaxSpy).toHaveBeenCalledWith(
      expect.objectContaining({
        url: '/api/v1/folders/999',
        data: expect.objectContaining({force: 'true'}),
      })
    )
  })

  it('only shows download button for limited users', () => {
    renderCog(sampleProps())
    expect(buttonsEnabled(readOnlyConfig)).toStrictEqual(true)
  })

  it('shows all buttons for users with manage_files permissions', () => {
    renderCog(sampleProps(true, true, true))
    expect(buttonsEnabled(manageFilesConfig)).toStrictEqual(true)
  })

  it('does not render rename/move buttons for users without manage_files_edit permission', () => {
    renderCog(sampleProps(true, false, true))
    expect(
      buttonsEnabled({
        ...manageFilesConfig,
        ...{editName: false, move: false, usageRights: false},
      })
    ).toStrictEqual(true)
  })

  it('does not render delete button for users without manage_files_delete permission', () => {
    renderCog(sampleProps(true, true, false))
    expect(buttonsEnabled({...manageFilesConfig, ...{deleteLink: false}})).toStrictEqual(true)
  })

  it('downloading a file returns focus back to the item cog', () => {
    renderCog(sampleProps())
    Simulate.click(screen.getByTestId('download'))
    expect(document.activeElement).toStrictEqual(document.querySelector('.al-trigger'))
  })

  // FOO-4355: invalid string length
  it.skip('deleting a file returns focus to the previous item cog when there are more items', () => {
    const props = sampleProps(true, true, true)
    props.model.destroy = function () {
      return true
    }

    // eslint-disable-next-line react/prefer-stateless-function
    class ContainerApp extends React.Component {
      render() {
        return (
          <div>
            <ItemCog {...props} />
            <ItemCog {...props} />
          </div>
        )
      }
    }

    render(<ContainerApp />, {container: document.getElementById('fixtures')})

    Simulate.click(screen.queryAllByTestId('deleteLink')[1])
    expect(document.activeElement).toStrictEqual(screen.queryAllByTestId('settingsCogBtn')[0])
  })

  // FOO-4355: toStrictEqual is not working
  it.skip('deleting a file returns focus to the name column header when there are no items left', () => {
    const props = sampleProps(true, true, true)
    props.model.destroy = function () {
      return true
    }

    // eslint-disable-next-line react/prefer-stateless-function
    class ContainerApp extends React.Component {
      render() {
        return (
          <div>
            <div className="ef-name-col">
              <a href="#" className="someFakeLink">
                Name column header
              </a>
            </div>
            <ItemCog {...props} />
          </div>
        )
      }
    }

    render(<ContainerApp />, {container: document.getElementById('fixtures')})

    Simulate.click(screen.queryAllByTestId('deleteLink')[0])
    expect(document.activeElement).toStrictEqual($('.someFakeLink')[0])
  })

  describe('Send To menu item', () => {
    const oldEnv = window.ENV

    beforeEach(() => {
      $('#fixtures').empty()
      $('#fixtures').append(`
        <div role="alert" id="flash_screenreader_holder"></div>
        <div id="direct-share-user-mount-point"></div>
      `)
      window.ENV.COURSE_ID = '101'
    })

    afterEach(() => {
      window.ENV = oldEnv
    })

    it('is present when the item is a file', () => {
      const props = {...sampleProps(), model: new File({id: '1'}), userCanEditFilesForContext: true}
      const {queryByRole} = renderCog(props)
      expect(queryByRole('menuitem', {hidden: true, name: 'Send To...'})).toBeInTheDocument()
    })

    it('is not present when the item is a folder', () => {
      const props = {...sampleProps(), userCanEditFilesForContext: true}
      const {queryByRole} = renderCog(props)
      expect(queryByRole('menuitem', {hidden: true, name: 'Send To...'})).not.toBeInTheDocument()
    })

    it('is not present when in a user context', () => {
      ENV.context_asset_string = 'user_17'
      const props = {...sampleProps(), userCanEditFilesForContext: true}
      const {queryByRole} = renderCog(props)
      expect(queryByRole('menuitem', {hidden: true, name: 'Send To...'})).not.toBeInTheDocument()
    })

    it('is not present when the user does not have edit files permissions', () => {
      const props = {...sampleProps(), model: new File({id: '1'})}
      const {queryByRole} = render(<ItemCog {...props} />)
      expect(queryByRole('menuitem', {hidden: true, name: 'Send To...'})).not.toBeInTheDocument()
    })

    it('calls onSendToClick when clicked', () => {
      const onSendToClickStub = jest.fn()
      const props = {
        ...sampleProps(),
        model: new File({id: '1'}),
        onSendToClick: onSendToClickStub,
        userCanEditFilesForContext: true,
      }
      const {queryByRole} = render(<ItemCog {...props} />)
      queryByRole('menuitem', {hidden: true, name: 'Send To...'}).click()
      expect(onSendToClickStub).toHaveBeenCalledTimes(1)
    })
  })

  describe('Copy To menu item', () => {
    beforeEach(() => {
      fetchMock.get('/users/self/manageable_courses?include=', 200)
      $('#fixtures').empty()
      $('#fixtures').append(`
        <div role="alert" id="flash_screenreader_holder"></div>
        <div id="direct-share-course-mount-point"></div>
      `)
    })

    afterEach(() => {
      fetchMock.restore()
    })

    it('is present when the item is a file', () => {
      const props = {...sampleProps(), model: new File({id: 1}), userCanEditFilesForContext: true}
      const {queryByRole} = renderCog(props)
      expect(queryByRole('menuitem', {hidden: true, name: 'Copy To...'})).toBeInTheDocument()
    })

    it('is not present when the item is a folder', () => {
      const props = {...sampleProps(), userCanEditFilesForContext: true}
      const {queryByRole} = renderCog(props)
      expect(queryByRole('menuitem', {hidden: true, name: 'Copy To...'})).not.toBeInTheDocument()
    })

    it('is not present when in a user context', () => {
      window.ENV.context_asset_string = 'user_17'
      const props = {...sampleProps(), userCanEditFilesForContext: true}
      const {queryByRole} = renderCog(props)
      expect(queryByRole('menuitem', {hidden: true, name: 'Copy To...'})).not.toBeInTheDocument()
    })

    it('is not present when the user does not have edit files permissions', () => {
      const props = {...sampleProps(), model: new File({id: '1'})}
      const {queryByRole} = renderCog(props)
      expect(queryByRole('menuitem', {hidden: true, name: 'Copy To...'})).not.toBeInTheDocument()
    })

    it('calls onCopyToClick when clicked', () => {
      const onCopyToClickStub = jest.fn()
      const props = {
        ...sampleProps(),
        model: new File({id: '1'}),
        onCopyToClick: onCopyToClickStub,
        userCanEditFilesForContext: true,
      }
      const {queryByRole} = renderCog(props)
      queryByRole('menuitem', {hidden: true, name: 'Copy To...'}).click()
      expect(onCopyToClickStub).toHaveBeenCalledTimes(1)
    })
  })
})
