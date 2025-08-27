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
import {render, screen, waitFor} from '@testing-library/react'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import BlueprintLockIcon from '../BlueprintLockIcon'
import {ContextModuleProvider, contextModuleDefaultProps} from '../../hooks/useModuleContext'

const server = setupServer()

const setUpMasterCourse = (initialLockState: boolean = false, courseId: string = '1') => {
  return render(
    <ContextModuleProvider {...contextModuleDefaultProps} courseId={courseId} isMasterCourse={true}>
      <BlueprintLockIcon
        initialLockState={initialLockState}
        contentId="1"
        contentType="assignment"
      />
    </ContextModuleProvider>,
  )
}

const setUpChildCourse = (initialLockState: boolean = false) => {
  return render(
    <ContextModuleProvider {...contextModuleDefaultProps} isChildCourse={true}>
      <BlueprintLockIcon
        initialLockState={initialLockState}
        contentId="1"
        contentType="assignment"
      />
    </ContextModuleProvider>,
  )
}

describe('BlueprintLockIcon', () => {
  describe('Master Course', () => {
    beforeAll(() => {
      server.use(
        http.post(
          '/api/v1/courses/:courseId/blueprint_templates/default/restrict_item',
          ({params}) => {
            const {courseId} = params
            if (courseId === '2') {
              return new HttpResponse(null, {status: 500})
            }
            return HttpResponse.json({success: true})
          },
        ),
      )
      server.listen()
    })

    afterAll(() => {
      server.resetHandlers()
      server.close()
    })

    it('renders', () => {
      const container = setUpMasterCourse()
      expect(container.container).toBeInTheDocument()
    })

    it('renders unlock button', () => {
      const {container, getAllByText} = setUpMasterCourse()
      // screenreader label and tooltip content
      expect(getAllByText('Unlocked. Click to lock.')).toHaveLength(2)
      expect(container.querySelector('[aria-pressed="false"]')).toBeInTheDocument()
      expect(container.querySelector('svg[name="IconBlueprintLock"]')).not.toBeInTheDocument()
      expect(container.querySelector('svg[name="IconBlueprint"]')).toBeInTheDocument()
    })

    it('renders lock icon', () => {
      const {container, getAllByText} = setUpMasterCourse(true)
      // screenreader label and tooltip content
      expect(getAllByText('Locked. Click to unlock.')).toHaveLength(2)
      expect(container.querySelector('[aria-pressed="true"]')).toBeInTheDocument()
      expect(container.querySelector('svg[name="IconBlueprintLock"]')).toBeInTheDocument()
      expect(container.querySelector('svg[name="IconBlueprint"]')).not.toBeInTheDocument()
    })

    it('calls the restrict_item api on clicking', async () => {
      const {container} = setUpMasterCourse()
      expect(container.querySelector('svg[name="IconBlueprint"]')).toBeInTheDocument()
      const button = container.querySelector('button')
      expect(button).toBeInTheDocument()
      button?.click()
      await waitFor(() => {
        expect(container.querySelector('svg[name="IconBlueprintLock"]')).toBeInTheDocument()
      })
    })

    it('shows a flash error message when the api fails', async () => {
      const {container} = setUpMasterCourse(false, '2')
      expect(container.querySelector('svg[name="IconBlueprint"]')).toBeInTheDocument()
      const button = container.querySelector('button')
      expect(button).toBeInTheDocument()
      button?.click()
      await waitFor(() => {
        expect(screen.getAllByText('An error occurred locking item')).toHaveLength(2)
      })
      expect(container.querySelector('svg[name="IconBlueprint"]')).toBeInTheDocument()
    })
  })

  describe('Child Course', () => {
    it('renders', () => {
      const container = setUpChildCourse()
      expect(container.container).toBeInTheDocument()
    })

    it('render unlocked icon', () => {
      const {container, getByText} = setUpChildCourse()

      expect(container.querySelector('svg[name="IconBlueprintLock"]')).not.toBeInTheDocument()
      expect(container.querySelector('svg[name="IconBlueprint"]')).toBeInTheDocument()
    })

    it('render lock icon', () => {
      const {container, getByText} = setUpChildCourse(true)

      expect(container.querySelector('svg[name="IconBlueprintLock"]')).toBeInTheDocument()
      expect(container.querySelector('svg[name="IconBlueprint"]')).not.toBeInTheDocument()
    })
  })
})
