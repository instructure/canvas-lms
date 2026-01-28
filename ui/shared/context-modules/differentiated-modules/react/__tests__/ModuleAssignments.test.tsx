/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {act, fireEvent, render} from '@testing-library/react'
import ModuleAssignments, {type ModuleAssignmentsProps} from '../ModuleAssignments'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {FILTERED_SECTIONS_DATA, FILTERED_STUDENTS_DATA, SECTIONS_DATA, STUDENTS_DATA} from './mocks'
import {queryClient} from '@canvas/query'
import {MockedQueryProvider} from '@canvas/test-utils/query'

const server = setupServer()

const props: ModuleAssignmentsProps = {
  courseId: '1',
  onSelect: vi.fn(),
  defaultValues: [],
}

describe('ModuleAssignments', () => {
  beforeAll(() => {
    if (!document.getElementById('flash_screenreader_holder')) {
      const liveRegion = document.createElement('div')
      liveRegion.id = 'flash_screenreader_holder'
      liveRegion.setAttribute('role', 'alert')
      document.body.appendChild(liveRegion)
    }
    server.listen()
  })

  beforeEach(() => {
    server.use(
      http.get(/\/api\/v1\/courses\/.+\/sections/, ({request}) => {
        const url = new URL(request.url)
        const searchTerm = url.searchParams.get('search_term')
        if (searchTerm) {
          return HttpResponse.json(FILTERED_SECTIONS_DATA)
        }
        return HttpResponse.json(SECTIONS_DATA)
      }),
      http.get(/\/api\/v1\/courses\/.+\/users/, () => {
        return HttpResponse.json(FILTERED_STUDENTS_DATA)
      }),
      http.get(/\/api\/v1\/courses\/.+\/settings/, () => {
        return HttpResponse.json({hide_final_grades: false})
      }),
    )
    queryClient.setQueryData(['students', props.courseId, {per_page: 100}], STUDENTS_DATA)
  })

  afterEach(() => {
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
  })

  const renderComponent = (overrides?: Partial<typeof props>) =>
    render(
      <MockedQueryProvider>
        <ModuleAssignments {...props} {...overrides} />
      </MockedQueryProvider>,
    )

  it('displays sections and students as options', async () => {
    const {findByTestId, findByText, getByText} = renderComponent()
    const moduleAssignments = await findByTestId('assignee_selector')
    act(() => moduleAssignments.click())
    await findByText(SECTIONS_DATA[0].name)
    SECTIONS_DATA.forEach(section => {
      expect(getByText(section.name)).toBeInTheDocument()
    })
    STUDENTS_DATA.forEach(student => {
      expect(getByText(student.value)).toBeInTheDocument()
    })
  })

  it('shows sis id in list', async () => {
    const {findByTestId, findByText, getByText} = renderComponent()
    const moduleAssignments = await findByTestId('assignee_selector')
    act(() => moduleAssignments.click())
    await findByText(STUDENTS_DATA[0].value)
    STUDENTS_DATA.forEach(student => {
      expect(getByText(student.sisID)).toBeInTheDocument()
    })
  })

  it('fetches filtered results from both APIs', async () => {
    const {findByTestId, findByText, getByText} = renderComponent()
    const moduleAssignments = await findByTestId('assignee_selector')
    act(() => moduleAssignments.click())
    fireEvent.change(moduleAssignments, {target: {value: 'sec'}})
    await findByText(FILTERED_SECTIONS_DATA[0].name)
    FILTERED_SECTIONS_DATA.forEach(section => {
      expect(getByText(section.name)).toBeInTheDocument()
    })
    FILTERED_STUDENTS_DATA.forEach(student => {
      expect(getByText(student.value)).toBeInTheDocument()
    })
  })

  it('allows filtering by SIS ID', async () => {
    const {findByTestId, findByText} = renderComponent()
    const moduleAssignments = await findByTestId('assignee_selector')
    act(() => moduleAssignments.click())
    fireEvent.change(moduleAssignments, {target: {value: 'raNDoM_iD_8'}})
    expect(await findByText('Secilia')).toBeInTheDocument()
  })

  it('shows SIS ID on existing options', async () => {
    const {findByTestId, findByText, getByTitle} = renderComponent({
      defaultValues: [
        {id: 'student-2', sisID: 'peter002', group: 'Students', overrideId: '1234', value: 'Peter'},
      ],
    })
    const moduleAssignments = await findByTestId('assignee_selector')
    act(() => moduleAssignments.click())
    act(() => getByTitle('Remove Peter').click())
    expect(await findByText('peter002')).toBeInTheDocument()
  })

  it('calls onSelect with parsed options', async () => {
    const onSelect = vi.fn()
    const {findByTestId, findByText} = renderComponent({onSelect})
    const moduleAssignments = await findByTestId('assignee_selector')
    act(() => moduleAssignments.click())
    const option1 = await findByText(SECTIONS_DATA[0].name)
    act(() => option1.click())
    expect(onSelect).toHaveBeenCalledWith([
      {group: 'Sections', id: `section-${SECTIONS_DATA[0].id}`, value: SECTIONS_DATA[0].name},
    ])
  })

  it('shows defaultValues as default selection', async () => {
    const defaultValues = [
      {id: '1', value: 'section A'},
      {id: '2', value: 'section B'},
    ]
    const {getAllByTestId, getByText} = renderComponent({defaultValues})
    expect(getByText(defaultValues[0].value)).toBeInTheDocument()
    expect(getByText(defaultValues[1].value)).toBeInTheDocument()
    expect(getAllByTestId('assignee_selector_selected_option')).toHaveLength(defaultValues.length)
  })
})
