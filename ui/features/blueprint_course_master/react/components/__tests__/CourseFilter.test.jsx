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

/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import CourseFilter from '../CourseFilter'
import getSampleData from './getSampleData'

const defaultProps = () => ({
  subAccounts: getSampleData().subAccounts,
  terms: getSampleData().terms,
})

describe('CourseFilter', () => {
  it('renders the CourseFilter component', () => {
    const {container} = render(<CourseFilter {...defaultProps()} />)
    const node = container.querySelector('.bca-course-filter')
    expect(node).toBeInTheDocument()
  })

  it('onChange fires with search filter when text is entered in search box', async () => {
    const props = defaultProps()
    const onChangePromise = new Promise(resolve => {
      props.onChange = filter => {
        expect(filter.search).toBe('giraffe')
        resolve()
      }
    })
    const {getByPlaceholderText} = render(<CourseFilter {...props} />)
    const input = getByPlaceholderText('Search by title, short name, or SIS ID')
    fireEvent.change(input, {target: {value: 'giraffe'}})
    await onChangePromise
  })

  it('onActivate fires when filters are focused', () => {
    const props = defaultProps()
    props.onActivate = jest.fn()
    const {getByPlaceholderText} = render(<CourseFilter {...props} />)
    const input = getByPlaceholderText('Search by title, short name, or SIS ID')
    fireEvent.focus(input)
    expect(props.onActivate).toHaveBeenCalledTimes(1)
  })

  it('onChange not fired when < 3 chars are entered in search text input', async () => {
    const props = defaultProps()
    props.onChange = jest.fn()
    const {getByPlaceholderText} = render(<CourseFilter {...props} />)
    const input = getByPlaceholderText('Search by title, short name, or SIS ID')
    fireEvent.change(input, {target: {value: 'aa'}})
    await new Promise(resolve => setTimeout(resolve, 0))
    expect(props.onChange).not.toHaveBeenCalled()
  })

  it('onChange fired when 3 chars are entered in search text input', async () => {
    const props = defaultProps()
    props.onChange = jest.fn()
    const {getByPlaceholderText} = render(<CourseFilter {...props} />)
    const input = getByPlaceholderText('Search by title, short name, or SIS ID')
    fireEvent.change(input, {target: {value: 'aaa'}})
    await new Promise(resolve => setTimeout(resolve, 0))
    expect(props.onChange).toHaveBeenCalledTimes(1)
  })

  describe('CourseFilter > Filter behavior', () => {
    it('onChange fires with term filter when term is selected', async () => {
      const props = defaultProps()
      const onChangeMock = jest.fn(filter => {
        expect(filter.term).toBe('1')
      })
      props.onChange = onChangeMock
      const {findByTitle, findByRole} = render(<CourseFilter {...props} />)
      const button = await findByTitle('Any Term')
      await userEvent.click(button)
      const option = await findByRole('option', {name: 'Term One'})
      expect(option).toBeInTheDocument()
      await userEvent.click(option)
    })

    it('onChange fires with subaccount filter when a subaccount is selected', async () => {
      const props = defaultProps()
      const onChangeMock = jest.fn(filter => {
        expect(filter.subAccount).toBe('1')
      })
      props.onChange = onChangeMock
      const {findByTitle, findByRole} = render(<CourseFilter {...props} />)
      const button = await findByTitle('Any Sub-Account')
      await userEvent.click(button)
      const option = await findByRole('option', {name: 'Account One'})
      expect(option).toBeInTheDocument()
      await userEvent.click(option)
    })
  })
})
