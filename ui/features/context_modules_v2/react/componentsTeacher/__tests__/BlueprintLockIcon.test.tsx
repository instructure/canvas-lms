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
import {render} from '@testing-library/react'
import BlueprintLockIcon, {LOCK_ICON_CLASS} from '../BlueprintLockIcon'
import {ContextModuleProvider, contextModuleDefaultProps} from '../../hooks/useModuleContext'

const setUpMasterCourse = (initialLockState: boolean = false) => {
  return render(
    <ContextModuleProvider {...contextModuleDefaultProps} isMasterCourse={true}>
      <BlueprintLockIcon initialLockState={initialLockState} contentId="" contentType="" />
    </ContextModuleProvider>,
  )
}

const setUpChildCourse = (initialLockState: boolean = false) => {
  return render(
    <ContextModuleProvider {...contextModuleDefaultProps} isChildCourse={true}>
      <BlueprintLockIcon initialLockState={initialLockState} contentId="" contentType="" />
    </ContextModuleProvider>,
  )
}

describe('BlueprintLockIcon', () => {
  describe('Master Course', () => {
    it('renders', () => {
      const container = setUpMasterCourse()
      expect(container.container).toBeInTheDocument()
    })

    it('renders unlock icon', () => {
      const container = setUpMasterCourse()
      expect(container.getByTestId(LOCK_ICON_CLASS.unlocked)).toBeInTheDocument()
      expect(container.queryByTestId(LOCK_ICON_CLASS.locked)).toBeNull()
    })

    it('renders lock icon', () => {
      const container = setUpMasterCourse(true)
      expect(container.getByTestId(LOCK_ICON_CLASS.locked)).toBeInTheDocument()
      expect(container.queryByTestId(LOCK_ICON_CLASS.unlocked)).toBeNull()
    })
  })

  describe('Child Course', () => {
    it('renders', () => {
      const container = setUpChildCourse()
      expect(container.container).toBeInTheDocument()
    })

    it('render disabled unlock icon', () => {
      const container = setUpChildCourse()
      expect(container.queryByTestId(LOCK_ICON_CLASS.unlocked)).toBeInTheDocument()
      expect(container.queryByTestId(LOCK_ICON_CLASS.unlocked)).toHaveClass('disabled')
    })

    it('render disabled lock icon', () => {
      const container = setUpChildCourse(true)
      expect(container.queryByTestId(LOCK_ICON_CLASS.locked)).toBeInTheDocument()
      expect(container.queryByTestId(LOCK_ICON_CLASS.locked)).toHaveClass('disabled')
    })
  })
})
