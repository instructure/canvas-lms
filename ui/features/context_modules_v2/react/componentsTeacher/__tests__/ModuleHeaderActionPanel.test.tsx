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

import React from 'react'
import {render, screen} from '@testing-library/react'
import ModuleHeaderActionPanel from '../ModuleHeaderActionPanel'

jest.mock('@canvas/context-modules/react/ContextModulesPublishIcon', () => ({
  __esModule: true,
  default: () => <div data-testid="publish-icon" />,
}))

jest.mock('../ModuleActionMenu', () => ({
  __esModule: true,
  default: () => <div data-testid="module-action-menu" />,
}))

jest.mock('@canvas/direct-sharing/react/components/DirectShareUserModal', () => ({
  __esModule: true,
  default: () => <div data-testid="direct-share-user-modal" />,
}))

jest.mock('@canvas/direct-sharing/react/components/DirectShareCourseTray', () => ({
  __esModule: true,
  default: () => <div data-testid="direct-share-course-tray" />,
}))

jest.mock('../AddItemModalComponents/AddItemModal', () => ({
  __esModule: true,
  default: () => <div data-testid="add-item-modal" />,
}))

jest.mock('../ViewAssignToTrayComponents/ViewAssignTo', () => ({
  __esModule: true,
  default: () => <div data-testid="view-assign-to" />,
}))

jest.mock('../../hooks/useModuleContext', () => ({
  useContextModule: () => ({courseId: 'course_123'}),
}))

describe('ModuleHeaderActionPanel', () => {
  const baseProps = {
    id: 'mod_1',
    name: 'Module 1',
    prerequisites: [],
    completionRequirements: [],
    requirementCount: 0,
    itemCount: 5,
    published: true,
    expanded: true,
    setModuleAction: jest.fn(),
    setIsManageModuleContentTrayOpen: jest.fn(),
    setSourceModule: jest.fn(),
  }

  it('renders ViewAssignTo when hasActiveOverrides is true', () => {
    render(<ModuleHeaderActionPanel {...baseProps} hasActiveOverrides={true} />)
    expect(screen.getByTestId('view-assign-to')).toBeInTheDocument()
  })

  it('does not render ViewAssignTo when hasActiveOverrides is false', () => {
    render(<ModuleHeaderActionPanel {...baseProps} hasActiveOverrides={false} />)
    expect(screen.queryByTestId('view-assign-to')).not.toBeInTheDocument()
  })
})
