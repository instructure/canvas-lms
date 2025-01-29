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
import {render} from '@testing-library/react'

import {EditTemplateModal} from '../EditTemplateModal'
import {type BlockTemplate} from '../../../types'

const template1: BlockTemplate = {
  id: '1',
  global_id: 'g_1',
  context_type: 'Course',
  context_id: '1',
  name: 'Template 1',
  description: 'This is template 1',
  node_tree: {rootNodeId: 'ROOT', nodes: {}},
  editor_version: '1.0',
  template_type: 'block',
  workflow_state: 'unpublished',
}

const renderModal = (props = {}) => {
  return render(
    <EditTemplateModal
      mode="save"
      isGlobalEditor={false}
      templateType="block"
      onDismiss={() => {}}
      onSave={() => {}}
      {...props}
    />,
  )
}

describe('EditTemplateModal', () => {
  it('should render', () => {
    const {getByRole, getByText, getByLabelText, queryByText} = renderModal()

    expect(getByRole('dialog')).toBeInTheDocument()
    expect(getByText('Template Name')).toBeInTheDocument()
    expect(getByText('Description')).toBeInTheDocument()
    expect(getByLabelText('Published')).not.toBeChecked()
    expect(getByText('Save')).toBeInTheDocument()
    expect(queryByText('Global template')).toBeNull()
  })

  it('should check the published checkbox when active', () => {
    const template = {...template1, workflow_state: 'active'}
    const {getByLabelText} = renderModal({template})

    expect(getByLabelText('Published')).toBeChecked()
  })

  it('should not show the Global Template checkbox for block templates', () => {
    const {queryByText} = renderModal({isGlobalEditor: true})

    expect(queryByText('Global template')).toBeNull()
  })

  it('should show the Global Template checkbox when isGlobalEditor is true and type is not "block"', () => {
    const {getByText} = renderModal({isGlobalEditor: true, templateType: 'page'})

    expect(getByText('Global template')).toBeInTheDocument()
  })

  it('should call onDismiss when the close button is clicked', () => {
    const onDismiss = jest.fn()
    const {getByText} = renderModal({onDismiss})

    // @ts-expect-error
    getByText('Close').closest('button').click()

    expect(onDismiss).toHaveBeenCalled()
  })

  it('should call onDismiss when the Cancel button is clicked', () => {
    const onDismiss = jest.fn()
    const {getByText} = renderModal({onDismiss})

    // @ts-expect-error
    getByText('Cancel').closest('button').click()

    expect(onDismiss).toHaveBeenCalled()
  })

  it('should call onSave with the correct values when the Save button is clicked', () => {
    const onSave = jest.fn()
    const template = {...template1, workflow_state: 'active'}
    const {getByText} = renderModal({template, onSave})

    // @ts-expect-error
    getByText('Save').closest('button').click()

    expect(onSave).toHaveBeenCalledWith(
      {name: template1.name, description: template1.description, workflow_state: 'active'},
      false,
    )
  })

  it('should show a message and not call onSave if there is no name', () => {
    const onSave = jest.fn()
    const {getByText, queryByText} = renderModal({onSave})

    expect(queryByText('A template name is required')).toBeNull()

    // @ts-expect-error
    getByText('Save').closest('button').click()

    expect(onSave).not.toHaveBeenCalled()
    expect(getByText('A template name is required')).toBeInTheDocument()
  })

  describe('when mode is save', () => {
    it('should render', () => {
      const {getByText} = renderModal()

      expect(getByText('Save as Template')).toBeInTheDocument()
    })
  })

  describe('when mode is edit', () => {
    it('should render', () => {
      const {getByText} = renderModal({mode: 'edit'})

      expect(getByText('Edit Template')).toBeInTheDocument()
    })
  })
})
