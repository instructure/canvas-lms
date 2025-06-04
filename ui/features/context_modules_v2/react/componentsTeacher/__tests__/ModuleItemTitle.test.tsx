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
import {ContextModuleProvider, contextModuleDefaultProps} from '../../hooks/useModuleContext'
import ModuleItemTitle from '../ModuleItemTitle'

const setUp = ({
  type = 'Assignment',
  title = 'Test Assignment',
  newTab = false,
}: {
  type?:
    | 'Assignment'
    | 'Quiz'
    | 'Discussion'
    | 'File'
    | 'Page'
    | 'ExternalUrl'
    | 'Attachment'
    | 'SubHeader'
  title?: string
  newTab?: boolean
} = {}) => {
  return render(
    <ContextModuleProvider {...contextModuleDefaultProps}>
      <ModuleItemTitle
        content={{type, title, isLockedByMasterCourse: false, newTab}}
        url="https://canvas.instructure.com/courses/1/modules"
      />
    </ContextModuleProvider>,
  )
}

describe('ModuleItemTitle', () => {
  it('renders', () => {
    const container = setUp({
      type: 'Assignment',
      title: 'Test Assignment',
    })
    expect(container.container).toBeInTheDocument()
    expect(container.getByTestId('module-item-title-link')).toBeInTheDocument()
  })

  it('renders new tab link', () => {
    const container = setUp({
      type: 'ExternalUrl',
      title: 'Test ExternalUrl',
      newTab: true,
    })
    expect(container.container).toBeInTheDocument()
    expect(container.getByText('Test ExternalUrl')).toBeInTheDocument()
    expect(container.getByTestId('external-link-icon')).toBeInTheDocument()
  })

  it('renders subheader', () => {
    const container = setUp({
      type: 'SubHeader',
      title: 'Test SubHeader',
    })
    expect(container.container).toBeInTheDocument()
    expect(container.getByText('Test SubHeader')).toBeInTheDocument()
    expect(container.getByTestId('subheader-title-text')).toBeInTheDocument()
  })
})
