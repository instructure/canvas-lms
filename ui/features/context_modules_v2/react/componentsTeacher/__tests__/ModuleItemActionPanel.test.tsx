/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {render, screen} from '@testing-library/react'
import ModuleItemActionPanel from '../ModuleItemActionPanel'

jest.mock('@canvas/files/react/components/PublishCloud', () =>
  jest.fn(() => <div data-testid="publish-cloud" />),
)

jest.mock('../../handlers/moduleItemActionHandlers', () => ({
  handlePublishToggle: jest.fn(),
  handleEdit: jest.fn(),
  handleSpeedGrader: jest.fn(),
  handleAssignTo: jest.fn(),
  handleDuplicate: jest.fn(),
  handleMoveTo: jest.fn(),
  handleDecreaseIndent: jest.fn(),
  handleIncreaseIndent: jest.fn(),
  handleSendTo: jest.fn(),
  handleCopyTo: jest.fn(),
  handleRemove: jest.fn(),
  handleMasteryPaths: jest.fn(),
}))

jest.mock('../../hooks/useModuleContext', () => ({
  useContextModule: () => ({
    courseId: '1',
    isMasterCourse: false,
    isChildCourse: false,
  }),
}))

describe('ModuleItemActionPanel', () => {
  const baseProps = {
    moduleId: '1',
    itemId: '123',
    id: '123',
    indent: 0,
    setModuleAction: jest.fn(),
    setSelectedModuleItem: jest.fn(),
    setIsManageModuleContentTrayOpen: jest.fn(),
    setSourceModule: jest.fn(),
    moduleTitle: 'Test Module',
    canBeUnpublished: true,
    masteryPathsData: null,
  }

  it('renders PublishCloud component for content type File', () => {
    render(
      <ModuleItemActionPanel
        {...baseProps}
        published={true}
        content={{
          _id: 'file1',
          id: 'file1',
          type: 'File',
          title: 'Test File',
          published: true,
          fileState: '',
        }}
      />,
    )

    expect(screen.getByTestId('publish-cloud')).toBeInTheDocument()
  })

  it('renders IconButton for non File content type', () => {
    render(
      <ModuleItemActionPanel
        {...baseProps}
        published={false}
        content={{
          _id: 'discussion1',
          id: 'discussion1',
          type: 'Discussion',
          title: 'Test Discussion',
          published: false,
        }}
      />,
    )

    expect(screen.getByText('Unpublished')).toBeInTheDocument()
  })
})
