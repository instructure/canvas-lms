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
import {fireEvent, render} from '@testing-library/react'
import {ContextModuleProvider, contextModuleDefaultProps} from '../../hooks/useModuleContext'
import ModuleItemActionMenu from '../ModuleItemActionMenu'

const setUp = (itemType: string = 'Assignment') => {
  return render(
    <ContextModuleProvider {...contextModuleDefaultProps}>
      <ModuleItemActionMenu
        itemType={itemType}
        canDuplicate={true}
        isMenuOpen={false}
        setIsMenuOpen={() => {}}
        indent={1}
        handleEdit={() => {}}
        handleSpeedGrader={() => {}}
        handleAssignTo={() => {}}
        handleDuplicate={() => {}}
        handleMoveTo={() => {}}
        handleDecreaseIndent={() => {}}
        handleIncreaseIndent={() => {}}
        handleSendTo={() => {}}
        handleCopyTo={() => {}}
        handleRemove={() => {}}
        masteryPathsData={{
          isCyoeAble: false,
          isTrigger: false,
          isReleased: false,
          releasedLabel: null,
        }}
        handleMasteryPaths={() => {}}
      />
    </ContextModuleProvider>,
  )
}

describe('ModuleItemActionMenu', () => {
  it('renders', () => {
    const container = setUp()
    expect(container.container).toBeInTheDocument()
  })

  it('renders menu with correct props', () => {
    const container = setUp()
    // Check that the Menu button is rendered
    const menuButton = container.getByRole('button', {name: 'Module Item Options'})
    expect(menuButton).toBeInTheDocument()
    fireEvent.click(menuButton)

    expect(container.getByText('Edit')).toBeInTheDocument()
    expect(container.getByText('SpeedGrader')).toBeInTheDocument()
    expect(container.getByText('Assign To...')).toBeInTheDocument()
    expect(container.getByText('Duplicate')).toBeInTheDocument()
    expect(container.getByText('Move to...')).toBeInTheDocument()
    expect(container.getByText('Decrease indent')).toBeInTheDocument()
    expect(container.getByText('Increase indent')).toBeInTheDocument()
    expect(container.getByText('Send To...')).toBeInTheDocument()
    expect(container.getByText('Copy To...')).toBeInTheDocument()
    expect(container.getByText('Remove')).toBeInTheDocument()
  })

  it('renders menu for basic content types', () => {
    const container = setUp('SubHeader')

    // Check that the Menu button is rendered
    const menuButton = container.getByRole('button', {name: 'Module Item Options'})
    expect(menuButton).toBeInTheDocument()
    fireEvent.click(menuButton)

    expect(container.getByText('Edit')).toBeInTheDocument()
    expect(container.queryByText('SpeedGrader')).not.toBeInTheDocument()
    expect(container.queryByText('Assign To...')).not.toBeInTheDocument()
    expect(container.queryByText('Duplicate')).not.toBeInTheDocument()
    expect(container.getByText('Move to...')).toBeInTheDocument()
    expect(container.getByText('Decrease indent')).toBeInTheDocument()
    expect(container.getByText('Increase indent')).toBeInTheDocument()
    expect(container.queryByText('Send To...')).not.toBeInTheDocument()
    expect(container.queryByText('Copy To...')).not.toBeInTheDocument()
    expect(container.getByText('Remove')).toBeInTheDocument()
  })
})
