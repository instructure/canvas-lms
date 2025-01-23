/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render, fireEvent, screen} from '@testing-library/react'
import UsageRightsDialog from '../UsageRightsDialog'
import File from '../../../backbone/models/File'
import Folder from '../../../backbone/models/Folder'

describe('UsageRightsDialog', () => {
  let defaultProps

  beforeEach(() => {
    const usageRights = {use_justification: 'choose'}
    defaultProps = {
      closeModal: jest.fn(),
      isOpen: true,
      itemsToManage: [
        new File({
          cid: '1',
          thumbnail_url: 'http://localhost/thumbnail.png',
          usage_rights: usageRights,
          displayName: () => 'test file',
        }),
      ],
    }
  })

  const renderDialog = (props = {}) => {
    return render(<UsageRightsDialog {...defaultProps} {...props} />)
  }

  it('displays dialog preview by default', () => {
    renderDialog()
    const preview = document.querySelector('.DialogPreview__thumbnail')
    expect(preview).toBeInTheDocument()
    expect(preview).toHaveStyle({backgroundImage: 'url(http://localhost/thumbnail.png)'})
  })

  it('does not display dialog preview when hidePreview is true', () => {
    const {container} = renderDialog({hidePreview: true})
    expect(container.querySelector('.UsageRightsDialog__previewColumn')).not.toBeInTheDocument()
  })

  it('closes modal when close button is clicked', () => {
    renderDialog()
    fireEvent.click(screen.getByRole('button', {name: /close/i}))
    expect(defaultProps.closeModal).toHaveBeenCalled()
  })

  it('closes modal when cancel button is clicked', () => {
    renderDialog()
    fireEvent.click(screen.getByRole('button', {name: /cancel/i}))
    expect(defaultProps.closeModal).toHaveBeenCalled()
  })

  it('renders the file count with multiple items', () => {
    const usageRights = {use_justification: 'choose'}
    const props = {
      itemsToManage: [
        new File({
          cid: '1',
          thumbnail_url: 'http://localhost/thumbnail.png',
          usage_rights: usageRights,
          displayName: () => 'file1',
        }),
        new File({
          cid: '2',
          thumbnail_url: 'http://localhost/thumbnail.png',
          usage_rights: usageRights,
          displayName: () => 'file2',
        }),
      ],
    }
    renderDialog(props)
    expect(screen.getByText('2 items selected')).toBeInTheDocument()
  })

  it('renders the file name with one item', () => {
    const [file] = defaultProps.itemsToManage
    file.displayName = () => 'cats'
    renderDialog()
    expect(screen.getByText('cats')).toBeInTheDocument()
  })

  it('renders "different rights" message when files have different rights', () => {
    const props = {
      itemsToManage: [
        new File({
          cid: '1',
          thumbnail_url: 'http://localhost/thumbnail.png',
          usage_rights: {use_justification: 'own_copyright'},
          displayName: () => 'cats',
        }),
        new File({
          cid: '2',
          thumbnail_url: 'http://localhost/thumbnail.png',
          usage_rights: {use_justification: 'used_by_permission'},
          displayName: () => 'dogs',
        }),
      ],
    }
    renderDialog(props)
    expect(screen.getByText('Items selected have different usage rights.')).toBeInTheDocument()
  })

  it('does not render different rights message when rights are the same', () => {
    const usageRights = {use_justification: 'own_copyright', legal_copyright: ''}
    const props = {
      itemsToManage: [
        new File({
          cid: '3',
          thumbnail_url: 'http://localhost/thumbnail.png',
          usage_rights: usageRights,
          displayName: () => 'cats',
        }),
        new File({
          cid: '4',
          thumbnail_url: 'http://localhost/thumbnail.png',
          usage_rights: usageRights,
          displayName: () => 'cats',
        }),
      ],
    }
    renderDialog(props)
    expect(
      screen.queryByText('Items selected have different usage rights.'),
    ).not.toBeInTheDocument()
  })

  it('renders folder message for one folder', () => {
    const usageRights = {use_justification: 'choose'}
    const folder = new Folder({cid: '1', usage_rights: usageRights})
    folder.displayName = () => 'some folder'
    renderDialog({itemsToManage: [folder]})
    const folderList = screen.getByRole('list', {class: /folderBulletList/})
    expect(folderList).toBeInTheDocument()
    expect(folderList).toHaveTextContent('some folder')
  })

  it('renders folder tooltip for multiple folders', () => {
    const usageRights = {use_justification: 'choose'}
    const folders = ['1', '2', '3', '4'].map(cid => {
      const folder = new Folder({cid, usage_rights: usageRights})
      folder.displayName = () => 'hello'
      return folder
    })
    renderDialog({itemsToManage: folders})
    expect(screen.getByText('and 2 more…')).toBeInTheDocument()
  })

  describe('Form Submission', () => {
    it('validates usage rights selection', () => {
      const usageRights = {use_justification: 'choose'}
      const file = new File({
        cid: '1',
        thumbnail_url: 'http://localhost/thumbnail.png',
        usage_rights: usageRights,
        displayName: () => 'hello',
      })
      renderDialog({itemsToManage: [file]})

      const submitButton = screen.getByRole('button', {name: /save/i})
      fireEvent.click(submitButton)
      expect(defaultProps.closeModal).not.toHaveBeenCalled()
    })
  })
})
