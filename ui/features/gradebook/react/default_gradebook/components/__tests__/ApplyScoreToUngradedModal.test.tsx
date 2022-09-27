/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import ApplyScoreToUngradedModal from '../ApplyScoreToUngradedModal'
import {fireEvent, render} from '@testing-library/react'

describe('ApplyScoreToUngradedModal', () => {
  const assignmentGroup = {
    id: '100',
    name: 'My Assignment Group',
  }

  let onApply: jest.Mock<any, any>
  let onClose: jest.Mock<any, any>

  beforeEach(() => {
    onApply = jest.fn()
    onClose = jest.fn()
  })

  function renderComponent(overrides = {}) {
    return render(
      <ApplyScoreToUngradedModal onApply={onApply} onClose={onClose} open={true} {...overrides} />
    )
  }

  it('includes the assignment group name when assignmentGroup is non-null', () => {
    const {getByRole} = renderComponent({assignmentGroup})
    expect(getByRole('dialog')).toHaveTextContent(
      /Select the score that you would like to apply to ungraded artifacts in My Assignment Group/
    )
  })

  it('calls onClose when the Cancel button is clicked', () => {
    const {getByRole} = renderComponent()
    fireEvent.click(getByRole('button', {name: /Cancel/}))
    expect(onClose).toHaveBeenCalled()
  })

  it('calls onClose when the modal close button is clicked', () => {
    const {getByRole} = renderComponent()
    fireEvent.click(getByRole('button', {name: /Close/}))
    expect(onClose).toHaveBeenCalled()
  })

  describe('input validation', () => {
    it('does not accept the initial empty value', () => {
      const {getByRole} = renderComponent()
      expect(getByRole('button', {name: /Apply Score/})).toBeDisabled()
    })

    it('accepts scores between 0 and 100', () => {
      const {getByRole} = renderComponent()
      fireEvent.change(getByRole('textbox'), {target: {value: '30'}})

      expect(getByRole('button', {name: /Apply Score/})).toBeEnabled()
    })

    it('does not accept a score below 0', () => {
      const {getByRole} = renderComponent()
      fireEvent.change(getByRole('textbox'), {target: {value: '-10'}})

      expect(getByRole('button', {name: /Apply Score/})).toBeDisabled()
    })

    it('does not accept a score above 100', () => {
      const {getByRole} = renderComponent()
      fireEvent.change(getByRole('textbox'), {target: {value: '1000000'}})

      expect(getByRole('button', {name: /Apply Score/})).toBeDisabled()
    })

    it('accepts the value EX', () => {
      const {getByRole} = renderComponent()
      fireEvent.change(getByRole('textbox'), {target: {value: 'Ex'}})

      expect(getByRole('button', {name: /Apply Score/})).toBeEnabled()
    })

    it('does not accept an empty value', () => {
      const {getByRole} = renderComponent()
      fireEvent.change(getByRole('textbox'), {target: {value: '       '}})

      expect(getByRole('button', {name: /Apply Score/})).toBeDisabled()
    })

    it('does not accept a non-EX, non-number value', () => {
      const {getByRole} = renderComponent()
      fireEvent.change(getByRole('textbox'), {target: {value: 'fred'}})

      expect(getByRole('button', {name: /Apply Score/})).toBeDisabled()
    })
  })

  describe('onApply', () => {
    it('is called with assignmentGroupId if an assignment group was passed', () => {
      const {getByRole} = renderComponent({assignmentGroup})
      fireEvent.change(getByRole('textbox'), {target: {value: '10'}})
      fireEvent.click(getByRole('button', {name: /Apply Score/}))
      expect(onApply).toHaveBeenCalledWith(expect.objectContaining({assignmentGroupId: '100'}))
    })

    it('is called with "value" set to the specified percent if a number was entered', () => {
      const {getByRole} = renderComponent({assignmentGroup})
      fireEvent.change(getByRole('textbox'), {target: {value: '10'}})
      fireEvent.click(getByRole('button', {name: /Apply Score/}))
      expect(onApply).toHaveBeenCalledWith(expect.objectContaining({value: 10}))
    })

    it('is called with "value" set to "excused" if EX was entered', () => {
      const {getByRole} = renderComponent({assignmentGroup})
      fireEvent.change(getByRole('textbox'), {target: {value: 'EX'}})
      fireEvent.click(getByRole('button', {name: /Apply Score/}))
      expect(onApply).toHaveBeenCalledWith(expect.objectContaining({value: 'excused'}))
    })

    it('is called with onlyPastDue set to true if limited to artifacts past due', () => {
      const {getByRole} = renderComponent({assignmentGroup})
      fireEvent.change(getByRole('textbox'), {target: {value: '10'}})
      fireEvent.click(getByRole('radio', {name: /Only ungraded artifacts that are past due/}))
      fireEvent.click(getByRole('button', {name: /Apply Score/}))
      expect(onApply).toHaveBeenCalledWith(expect.objectContaining({onlyPastDue: true}))
    })

    it('is called with onlyPastDue set to false if not limited to past-due artifacts', () => {
      const {getByRole} = renderComponent({assignmentGroup})
      fireEvent.change(getByRole('textbox'), {target: {value: '10'}})
      fireEvent.click(getByRole('radio', {name: /All ungraded artifacts/}))
      fireEvent.click(getByRole('button', {name: /Apply Score/}))
      expect(onApply).toHaveBeenCalledWith(expect.objectContaining({onlyPastDue: false}))
    })

    it('is called with markAsMissing set to true if also marking submissions as missing', () => {
      const {getByRole} = renderComponent({assignmentGroup})
      fireEvent.change(getByRole('textbox'), {target: {value: '10'}})
      fireEvent.click(getByRole('checkbox', {name: /Apply missing status/}))
      fireEvent.click(getByRole('button', {name: /Apply Score/}))
      expect(onApply).toHaveBeenCalledWith(expect.objectContaining({markAsMissing: true}))
    })

    it('is called with markAsMissing set to false if not marking submissions as missing', () => {
      const {getByRole} = renderComponent({assignmentGroup})
      fireEvent.change(getByRole('textbox'), {target: {value: '10'}})
      fireEvent.click(getByRole('button', {name: /Apply Score/}))
      expect(onApply).toHaveBeenCalledWith(expect.objectContaining({markAsMissing: false}))
    })
  })
})
