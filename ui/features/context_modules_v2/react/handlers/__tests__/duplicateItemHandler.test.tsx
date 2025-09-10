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

import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {QueryClient} from '@tanstack/react-query'
import {handleDuplicate} from '../moduleItemActionHandlers'
import {MODULE_ITEMS, MODULES} from '../../utils/constants'
import {MenuItemActionState, PerModuleState} from '../../utils/types'
import React from 'react'
import {render, screen} from '@testing-library/react'
import ModuleItemList from '../../componentsTeacher/ModuleItemList'
import {
  ContextModuleProvider,
  useContextModule,
  contextModuleDefaultProps,
} from '../../hooks/useModuleContext'
import {DragDropContext} from 'react-beautiful-dnd'
import userEvent from '@testing-library/user-event'

// eslint-disable-next-line promise/param-names
const waitTick = () => new Promise(r => setTimeout(r, 0))

const courseId = '42'
const moduleId = 'mod-123'
const itemId = 'itm-9'
const duplicatePath = `/api/v1/courses/${courseId}/modules/items/${itemId}/duplicate`
const baseProviderProps = {
  courseId: '42',
  isMasterCourse: false,
  isChildCourse: false,
  permissions: contextModuleDefaultProps.permissions,
  NEW_QUIZZES_ENABLED: contextModuleDefaultProps.NEW_QUIZZES_ENABLED,
  NEW_QUIZZES_BY_DEFAULT: contextModuleDefaultProps.NEW_QUIZZES_BY_DEFAULT,
  DEFAULT_POST_TO_SIS: contextModuleDefaultProps.DEFAULT_POST_TO_SIS,
  teacherViewEnabled: true,
  studentViewEnabled: true,
  restrictQuantitativeData: false,
  isObserver: false,
  observedStudent: null,
  moduleMenuModalTools: [],
  moduleGroupMenuTools: [],
  moduleMenuTools: [],
  moduleIndexMenuModalTools: [],
}

const server = setupServer(
  http.post(duplicatePath, () => HttpResponse.json({ok: true}, {status: 200})),
)

const SetDuplicateLoading: React.FC<{moduleId: string}> = ({moduleId}) => {
  const {setMenuItemLoadingState} = useContextModule()
  React.useEffect(() => {
    setMenuItemLoadingState(prev => ({
      ...prev,
      [moduleId]: {state: true, type: 'duplicate'},
    }))
  }, [moduleId, setMenuItemLoadingState])
  return null
}

const openItemMenu = async () => {
  const byTestId = screen.queryByTestId('module-item-action-menu-button')
  if (byTestId) {
    await userEvent.click(byTestId)
    return
  }

  const srLabel = screen.queryByText(/Module Item Options/i)
  if (!srLabel) {
    throw new Error('Could not find "Module Item Options" label')
  }

  const btn = srLabel.closest('button')
  if (!btn) {
    throw new Error('Could not find menu button')
  }

  await userEvent.click(btn)
}

beforeAll(() => {
  if (!(global as any).fetch) {
    const {default: fetch} = require('node-fetch')
    ;(global as any).fetch = fetch
  }
  server.listen({onUnhandledRequest: 'error'})
})
afterEach(() => server.resetHandlers())
afterAll(() => server.close())

describe('handleDuplicate', () => {
  let queryClient: QueryClient
  let invalidateCalls: Array<{queryKey: unknown[]}>
  let menuItemLoadingState: PerModuleState<MenuItemActionState>
  let setIsMenuOpenCalls: boolean[]

  const getDuplicateLoadingState = (menuItemLoadingState: any) =>
    menuItemLoadingState?.[moduleId]?.state

  const setIsMenuOpen = (b: boolean) => setIsMenuOpenCalls.push(b)
  const setMenuItemLoading: React.Dispatch<
    React.SetStateAction<PerModuleState<MenuItemActionState>>
  > = update =>
    (menuItemLoadingState = typeof update === 'function' ? update(menuItemLoadingState) : update)

  beforeEach(() => {
    invalidateCalls = []
    menuItemLoadingState = {}
    setIsMenuOpenCalls = []

    queryClient = new QueryClient()
    const originalInvalidate = queryClient.invalidateQueries.bind(queryClient)
    ;(queryClient as any).invalidateQueries = (arg: any) => {
      invalidateCalls.push(arg)
      return originalInvalidate(arg)
    }
  })

  it('success: posts to duplicate endpoint, shows success path effects, invalidates caches, toggles loading, closes menu', async () => {
    handleDuplicate(moduleId, itemId, queryClient, courseId, setMenuItemLoading, setIsMenuOpen)
    expect(setIsMenuOpenCalls).toEqual([false])
    expect(getDuplicateLoadingState(menuItemLoadingState)).toEqual(true)

    await waitTick()
    expect(invalidateCalls).toEqual(
      expect.arrayContaining([
        {queryKey: [MODULE_ITEMS, moduleId]},
        {queryKey: [MODULES, courseId]},
      ]),
    )
    expect(getDuplicateLoadingState(menuItemLoadingState)).toEqual(undefined)
  })

  it('error: when API fails, shows error path effects, no invalidations, loading off, menu closes', async () => {
    server.use(http.post(duplicatePath, () => HttpResponse.json({error: 'nope'}, {status: 500})))
    handleDuplicate(moduleId, itemId, queryClient, courseId, setMenuItemLoading, setIsMenuOpen)
    expect(setIsMenuOpenCalls).toEqual([false])
    expect(getDuplicateLoadingState(menuItemLoadingState)).toEqual(true)

    await waitTick()
    expect(invalidateCalls).toEqual([])
    expect(getDuplicateLoadingState(menuItemLoadingState)).toEqual(undefined)
  })

  it('works when setIsMenuOpen is not provided', async () => {
    handleDuplicate(moduleId, itemId, queryClient, courseId, setMenuItemLoading)
    await waitTick()
    expect(getDuplicateLoadingState(menuItemLoadingState)).toEqual(undefined)
    expect(invalidateCalls).toEqual(
      expect.arrayContaining([
        {queryKey: [MODULE_ITEMS, moduleId]},
        {queryKey: [MODULES, courseId]},
      ]),
    )
    expect(setIsMenuOpenCalls).toEqual([])
  })
})

describe('ModuleItemList duplicate loading banner', () => {
  function renderUnderRealProvider(ui: React.ReactNode) {
    return render(
      <ContextModuleProvider {...baseProviderProps}>
        <DragDropContext onDragEnd={() => {}}>{ui}</DragDropContext>
      </ContextModuleProvider>,
    )
  }

  it('renders duplicate loading text and disables module item menu actions', async () => {
    renderUnderRealProvider(
      <>
        <SetDuplicateLoading moduleId={moduleId} />
        <ModuleItemList
          moduleId={moduleId}
          moduleTitle="Module A"
          isEmpty={false}
          error={null}
          moduleItems={[
            {
              id: 'itm-9',
              _id: 'itm-9',
              url: '#',
              title: 'Dup me',
              indent: 0,
              content: {id: 'c-1', _id: 'c-1', published: true, canUnpublish: true} as any,
              position: 0,
              masterCourseRestrictions: null,
            },
          ]}
        />
      </>,
    )
    expect(await screen.findByText('Duplicating module item…', {selector: 'span'})).toBeVisible()

    await openItemMenu()
    const items = screen.getAllByRole('menuitem')
    items.forEach(el => expect(el).toHaveAttribute('aria-disabled', 'true'))
    ;['Edit', 'Duplicate', 'Move to...', 'Remove'].forEach(label => {
      const mi = screen.queryByRole('menuitem', {name: label})
      if (mi) expect(mi).toHaveAttribute('aria-disabled', 'true')
    })
  })
})
