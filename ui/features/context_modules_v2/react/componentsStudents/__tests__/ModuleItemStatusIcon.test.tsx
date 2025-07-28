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
import ModuleItemStatusIcon from '../ModuleItemStatusIcon'
import {ModuleItemContent} from '../../utils/types'

interface TestPropsOverrides {
  moduleCompleted?: boolean
  content?: Partial<ModuleItemContent>
  dueDateOffsetHours?: number
}

const buildDefaultProps = (overrides: TestPropsOverrides = {}) => {
  // Set up due date
  const dueDateOffsetHours = overrides.dueDateOffsetHours ?? 72
  const dueDate = new Date(Date.now() + dueDateOffsetHours * 60 * 60 * 1000)

  // Create default content
  const defaultContent: ModuleItemContent = {
    _id: 'item-1',
    submissionsConnection: {
      nodes: [
        {
          _id: 'submission-1',
          cachedDueDate: dueDate.toISOString(),
          missing: overrides.dueDateOffsetHours && overrides.dueDateOffsetHours < 0 ? true : false,
        },
      ],
    },
    ...overrides.content,
  }

  return {
    moduleCompleted: overrides?.moduleCompleted ?? false,
    content: defaultContent,
  }
}

const setUp = (overrides: TestPropsOverrides = {}) => {
  const {moduleCompleted, content} = buildDefaultProps(overrides)
  return render(<ModuleItemStatusIcon moduleCompleted={moduleCompleted} content={content} />)
}

describe('ModuleItemStatusIcon', () => {
  it('should render "Complete" when module is completed', () => {
    const container = setUp({
      moduleCompleted: true,
      dueDateOffsetHours: 72,
    })
    expect(container.container).toBeInTheDocument()
    expect(container.getByText('Complete')).toBeInTheDocument()
  })

  it('should render "Missing" when submission is marked as missing', () => {
    const container = setUp({
      moduleCompleted: false,
      content: {
        submissionsConnection: {
          nodes: [
            {
              _id: 'submission-1',
              missing: true,
            },
          ],
        },
      },
    })
    expect(container.container).toBeInTheDocument()
    expect(container.getByText('Missing')).toBeInTheDocument()
  })

  it('should not render "Missing" when module is completed', () => {
    const container = setUp({
      moduleCompleted: true,
      content: {
        submissionsConnection: {
          nodes: [
            {
              _id: 'submission-1',
              missing: true,
            },
          ],
        },
      },
    })
    expect(container.container).toBeInTheDocument()
    expect(container.getByText('Complete')).toBeInTheDocument()
    expect(container.queryByText('Missing')).not.toBeInTheDocument()
  })

  it('should render nothing when no content is provided', () => {
    const container = setUp({
      moduleCompleted: false,
      content: undefined,
    })
    expect(container.container).toBeInTheDocument()
    expect(container.container).toBeEmptyDOMElement()
  })

  it('should render nothing when submissions array is empty', () => {
    const container = setUp({
      moduleCompleted: false,
      content: {
        submissionsConnection: {
          nodes: [],
        },
      },
    })
    expect(container.container).toBeInTheDocument()
    expect(container.container).toBeEmptyDOMElement()
  })

  it('should render nothing when submissions are undefined', () => {
    const container = setUp({
      moduleCompleted: false,
      content: {
        submissionsConnection: undefined,
      },
    })
    expect(container.container).toBeInTheDocument()
    expect(container.container).toBeEmptyDOMElement()
  })
})
