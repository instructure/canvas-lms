/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {fireEvent, render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import GradeSelect, {NO_SELECTION_LABEL} from '../GradeSelect'
import {FAILURE, STARTED, SUCCESS} from '../../../grades/GradeActions'
import {cloneDeep} from 'lodash'

const STUDENT_NAME = 'Daniel Martin Lukacs'

const DEFAULT_PROPS = {
  disabledCustomGrade: false,
  finalGrader: {
    graderId: 'teach',
    id: '1105',
  },
  graders: [
    {graderId: 'frizz', graderName: 'Miss Frizzle', graderSelectable: true},
    {graderId: 'robin', graderName: 'Mr. Keating', graderSelectable: true},
    {graderId: 'ednak', graderName: 'Mrs. Krabappel', graderSelectable: true},
    {graderId: 'feeny', graderName: 'Mr. Feeny', graderSelectable: true},
  ],
  grades: {
    frizz: {
      grade: 'A',
      graderId: 'frizz',
      id: '4601',
      score: 10,
      selected: false,
      studentId: '1111',
    },
    robin: {
      grade: 'B',
      graderId: 'robin',
      id: '4602',
      score: 8.6,
      selected: false,
      studentId: '1111',
    },
    feeny: {
      grade: 'C+',
      graderId: 'feeny',
      id: '4603',
      score: 7.9,
      selected: false,
      studentId: '1111',
    },
  },
  onSelect: Function.prototype,
  selectProvisionalGradeStatus: null,
  studentId: '1111',
  studentName: STUDENT_NAME,
}

function mountComponent(props) {
  const result = render(<GradeSelect {...props} />)
  const input = result.container.querySelector('input')
  return {...result, input}
}

async function mountAndClick(props) {
  const result = mountComponent(props)
  const {input} = result
  const menu = await clickAndWaitForMenu(input)
  return {...result, menu}
}

function getMenu(input) {
  const id = input.attributes.getNamedItem('aria-controls')?.value
  return id ? document.getElementById(id) : null
}

function waitForMenu(input) {
  return waitFor(() => {
    const menu = getMenu(input)
    if (!menu) throw new Error('Options list never showed up')
    return menu
  })
}

const clickAndWaitForMenu = async input => {
  await userEvent.click(input, {bubbles: true, cancelable: true})
  return waitForMenu(input)
}

function waitForMenuClosed(input) {
  return waitFor(() => {
    const menu = getMenu(input)
    if (menu) throw new Error('Options list never went away')
    return true
  })
}

function clickOffAndWaitForMenu(input) {
  fireEvent.blur(input)
  return waitForMenuClosed(input)
}

function optionsInList(list) {
  return Array.from(list.querySelectorAll('li [role="option"]'))
}

function findOption(list, label) {
  return optionsInList(list).find(opt => opt.textContent.trim() === label)
}

describe('GradeSummary::GradeSelect', () => {
  let props

  beforeEach(() => {
    props = cloneDeep(DEFAULT_PROPS)
  })

  function labelForGrader(id) {
    const gradeInfo = props.grades[id]
    const grader = props.graders.find(g => g.graderId === id)
    return `${gradeInfo.score} (${grader.graderName})`
  }

  const customLabel = score => `${score} (Custom)`

  it('renders a text input', () => {
    const {container} = mountComponent(props)
    expect(container.querySelector('input[type="text"]')).toBeInTheDocument()
  })

  it('uses the student name for a label', () => {
    const {getByText} = mountComponent(props)
    expect(getByText(`Grade for ${STUDENT_NAME}`)).toBeInTheDocument()
  })

  describe('when a grade has been selected', () => {
    beforeEach(() => {
      props.grades.robin.selected = true
    })

    it('does not include the option for "no selection"', async () => {
      const {menu} = await mountAndClick(props)
      optionsInList(menu).forEach(opt => {
        expect(opt.textContent).not.toContain(NO_SELECTION_LABEL)
      })
    })

    it('does not include an option for graders who did not grade', async () => {
      const {menu} = await mountAndClick(props)
      optionsInList(menu).forEach(opt => {
        expect(opt.textContent).not.toMatch(/Krabappel/)
      })
    })

    it('includes an option for each grader who graded', async () => {
      const {menu} = await mountAndClick(props)
      const labels = optionsInList(menu).map(opt => opt.textContent.trim())
      const desiredLabels = ['frizz', 'robin', 'feeny'].map(labelForGrader)
      expect(labels).toEqual(desiredLabels)
    })

    it('sets as the input value the selected provisional grade', () => {
      const {input} = mountComponent(props)
      expect(input.value).toBe(labelForGrader('robin'))
    })
  })

  describe('when the input is dismissed by clicking elsewhere', () => {
    it('does not call the onSelect prop', async () => {
      const onSelect = jest.fn()
      const {input} = await mountAndClick({...props, onSelect})
      await clickOffAndWaitForMenu(input)
      expect(onSelect).not.toHaveBeenCalled()
    })

    it('does not call the onSelect prop when the input was changed', async () => {
      const onSelect = jest.fn()
      const {input} = await mountAndClick({...props, onSelect})
      await userEvent.type(input, '7.9')
      await clickOffAndWaitForMenu(input)
      expect(onSelect).not.toHaveBeenCalled()
    })

    it('does not call the onSelect prop when the input was cleared', async () => {
      const onSelect = jest.fn()
      const {input} = await mountAndClick({...props, onSelect})
      fireEvent.input(input, {target: {value: ''}})
      await clickOffAndWaitForMenu(input)
      expect(onSelect).not.toHaveBeenCalled()
    })

    it('resets the input to the selected option', async () => {
      props.grades.robin.selected = true
      const {input} = await mountAndClick(props)
      await userEvent.type(input, 'gibberish')
      await clickOffAndWaitForMenu(input)
      expect(input.value).toBe(labelForGrader('robin'))
    })

    it('resets the input to the selected custom option', async () => {
      const score = 12

      props.grades.teach = {
        grade: 'C-',
        graderId: 'teach',
        id: '9999',
        score,
        selected: true,
        studentId: '1111',
      }

      const {input} = await mountAndClick(props)
      await userEvent.type(input, 'gibberish')
      await clickOffAndWaitForMenu(input)
      expect(input.value).toBe(customLabel(score))
    })

    it('resets the input to the "no selection" option when no grade is selected', async () => {
      const {input} = await mountAndClick(props)
      fireEvent.input(input, {target: {value: ''}})
      await clickOffAndWaitForMenu(input)
      expect(input.value).toBe(NO_SELECTION_LABEL)
    })

    it('resets the input to the "no selection" option when some text has been entered', async () => {
      const {input} = await mountAndClick(props)
      await userEvent.type(input, '10')
      await clickOffAndWaitForMenu(input)
      expect(input.value).toBe(NO_SELECTION_LABEL)
    })

    it('restores the full list of options for subsequent selection', async () => {
      const {input} = await mountAndClick(props)
      await userEvent.type(input, '{selectall}{backspace}7.9') // this is Mr. Feeny's grade
      await clickOffAndWaitForMenu(input)
      const menu = await clickAndWaitForMenu(input)
      const labels = optionsInList(menu).map(opt => opt.textContent.trim())
      const desiredLabels = ['frizz', 'robin', 'feeny'].map(labelForGrader)
      expect(labels).toEqual([...desiredLabels, customLabel(7.9)])
    })
  })

  describe('when no grade has been selected', () => {
    it('displays the grade and grader name as option labels', async () => {
      const {menu} = await mountAndClick(props)
      const labels = optionsInList(menu).map(opt => opt.textContent.trim())
      const desiredLabels = ['frizz', 'robin', 'feeny'].map(labelForGrader)
      expect(labels).toEqual(desiredLabels)
    })

    it('sets the input value to the no selection label', () => {
      const {input} = mountComponent(props)
      expect(input.value).toBe(NO_SELECTION_LABEL)
    })
  })

  describe('when selecting an existing grade', () => {
    it('calls the onSelect callback', async () => {
      const onSelect = jest.fn()
      const {input, menu} = await mountAndClick({...props, onSelect})
      const opt = findOption(menu, labelForGrader('frizz'))
      await userEvent.click(opt)
      await waitForMenuClosed(input)
      expect(onSelect).toHaveBeenCalledTimes(1)
    })

    it('passes the related grade info to the callback', async () => {
      const onSelect = jest.fn()
      const {input, menu} = await mountAndClick({...props, onSelect})
      const opt = findOption(menu, labelForGrader('frizz'))
      await userEvent.click(opt)
      await waitForMenuClosed(input)
      expect(onSelect).toHaveBeenCalledWith(props.grades.frizz)
    })

    it('does not call the callback when the option for the selected grade is clicked', async () => {
      props.grades.robin.selected = true
      const onSelect = jest.fn()
      const {input, menu} = await mountAndClick({...props, onSelect})
      const opt = findOption(menu, labelForGrader('robin'))
      await userEvent.click(opt)
      await waitForMenuClosed(input)
      expect(onSelect).not.toHaveBeenCalled()
    })
  })

  describe('when a custom grade exists for the final grader', () => {
    const score = 11

    beforeEach(() => {
      props.grades.teach = {
        grade: 'C-',
        graderId: 'teach',
        id: '9999',
        score,
        selected: false,
        studentId: '1111',
      }
    })

    it('includes a custom grade option', async () => {
      const {menu} = await mountAndClick(props)
      const labels = optionsInList(menu).map(opt => opt.textContent.trim())
      expect(labels).toContain(customLabel(score))
    })

    it('updates the custom grade option when a custom grade is entered', async () => {
      const newScore = '12'
      const {input, menu} = await mountAndClick(props)
      fireEvent.change(input, {target: {value: newScore}})
      const labels = optionsInList(menu).map(opt => opt.textContent.trim())
      expect(labels).toContain(customLabel(newScore))
    })

    it('does not include multiple custom grades', async () => {
      const {input, menu} = await mountAndClick(props)
      fireEvent.change(input, {target: {value: '83'}})
      const customLabels = optionsInList(menu)
        .map(opt => opt.textContent)
        .filter(s => s.match(/Custom/))
      expect(customLabels).toHaveLength(1)
    })

    describe('when clicking the custom grade option', () => {
      it('does not call the onSelect callback when the custom grade is selected', async () => {
        props.grades.teach.selected = true
        const onSelect = jest.fn()
        const {input, menu} = await mountAndClick({...props, onSelect})
        const opt = findOption(menu, customLabel(score))
        await userEvent.click(opt)
        await waitForMenuClosed(input)
        expect(onSelect).not.toHaveBeenCalled()
      })

      it('calls the onSelect callback when the custom grade is not selected', async () => {
        const onSelect = jest.fn()
        const {input, menu} = await mountAndClick({...props, onSelect})
        const opt = findOption(menu, customLabel(score))
        await userEvent.click(opt)
        await waitForMenuClosed(input)
        expect(onSelect).toHaveBeenCalledTimes(1)
      })

      it('includes the custom grade info when calling the onSelect callback', async () => {
        const onSelect = jest.fn()
        const {input, menu} = await mountAndClick({...props, onSelect})
        const opt = findOption(menu, customLabel(score))
        await userEvent.click(opt)
        await waitForMenuClosed(input)
        expect(onSelect).toHaveBeenCalledWith(props.grades.teach)
      })

      it('calls the onSelect callback when entered text has changed the selected custom grade', async () => {
        props.grades.teach.selected = true
        const onSelect = jest.fn()
        const {input} = await mountAndClick({...props, onSelect})
        fireEvent.change(input, {target: {value: '5'}})
        fireEvent.keyDown(input, {keyCode: 13})
        await waitForMenuClosed(input)
        expect(onSelect).toHaveBeenCalledTimes(1)
      })

      it('updates the custom grade info sent to the callback with the changed score', async () => {
        const newScore = '55'
        props.grades.teach.selected = true
        const onSelect = jest.fn()
        const {input} = await mountAndClick({...props, onSelect})
        fireEvent.change(input, {target: {value: newScore}})
        fireEvent.keyDown(input, {keyCode: 13})
        await waitForMenuClosed(input)
        expect(onSelect).toHaveBeenCalledWith({...props.grades.teach, score: Number(newScore)})
      })
    })
  })

  it('does not include a custom grade option when no custom grade exists for the final grader', async () => {
    const {menu} = await mountAndClick(props)
    expect(optionsInList(menu).map(opt => opt.textContent)).toEqual(
      ['frizz', 'robin', 'feeny'].map(labelForGrader)
    )
  })

  describe('when the assignment does not have a final grader', () => {
    it('does not include a custom grade option', async () => {
      const {menu} = await mountAndClick({...props, finalGrader: null})
      expect(optionsInList(menu).map(opt => opt.textContent)).toEqual(
        ['frizz', 'robin', 'feeny'].map(labelForGrader)
      )
    })

    it('allows selecting other grades', async () => {
      const onSelect = jest.fn()
      const {input, menu} = await mountAndClick({...props, onSelect, finalGrader: null})
      const opt = findOption(menu, labelForGrader('robin'))
      await userEvent.click(opt)
      await waitForMenuClosed(input)
      expect(onSelect).toHaveBeenCalledWith(props.grades.robin)
    })
  })

  describe('when a grade selection is pending', () => {
    it('sets the input to read-only while grade selection is pending', () => {
      const {input} = mountComponent({...props, selectProvisionalGradeStatus: STARTED})
      expect(input.attributes.getNamedItem('disabled')).toBeTruthy()
    })

    it('enables the input when grade selection was successful', () => {
      const {input} = mountComponent({...props, selectProvisionalGradeStatus: SUCCESS})
      expect(input.attributes.getNamedItem('disabled')).not.toBeTruthy()
    })

    it('enables the input when grade selection has failed', () => {
      const {input} = mountComponent({...props, selectProvisionalGradeStatus: FAILURE})
      expect(input.attributes.getNamedItem('disabled')).not.toBeTruthy()
    })
  })

  describe('when not given an onSelect prop (grades have been published)', () => {
    it('disables the input', () => {
      props.grades.frizz.selected = true
      props.onSelect = null
      const {input} = mountComponent(props)
      expect(input.attributes.getNamedItem('disabled')).toBeTruthy()
    })
  })

  describe('when custom grades cannot be edited', () => {
    /*
     * This is temporary until users beyond provisional graders and the final
     * grader are allowed to grade. Doing this will prevent as-yet-unexplored
     * scenarios from causing as-yet-unconsidered problems.
     */
    it('prevents the entering of a custom grade', async () => {
      const {input} = await mountAndClick({...props, disabledCustomGrade: true})
      fireEvent.change(input, {target: {value: '5'}})
      expect(input.value).toBe(NO_SELECTION_LABEL)
    })

    it('does not prevent selecting an existing grade', async () => {
      const onSelect = jest.fn()
      const {input, menu} = await mountAndClick({...props, disabledCustomGrade: true, onSelect})
      const opt = findOption(menu, labelForGrader('robin'))
      await userEvent.click(opt)
      await waitForMenuClosed(input)
      expect(onSelect).toHaveBeenCalledWith(props.grades.robin)
    })
  })

  describe('when entered text partially matches other grades (even with surrounding whitespace!)', () => {
    let menu
    let labels

    beforeEach(async () => {
      const {input, menu: mountedMenu} = await mountAndClick(props)
      menu = mountedMenu
      fireEvent.change(input, {target: {value: '   8   '}})
      await waitFor(() => expect(input.value).toBe('8   ')) // component trims leading space but allows trailing
      labels = optionsInList(menu).map(e => e.textContent)
    })

    it('includes only options matching the entered text', async () => {
      expect(labels).not.toContain(labelForGrader('frizz'))
      expect(labels).toContain(labelForGrader('robin'))
    })

    it('adds a custom grade when typed in and puts it last', () => {
      expect(labels).toEqual([labelForGrader('robin'), customLabel('8')])
    })
  })

  describe('when entered text exactly matches other grades (even with surrounding whitespace!)', () => {
    let menu
    let labels

    beforeEach(async () => {
      props.grades.frizz.score = 7.9
      props.grades.feeny.score = 7
      const {input, menu: mountedMenu} = await mountAndClick(props)
      menu = mountedMenu
      fireEvent.change(input, {target: {value: '   7   '}})
      await waitFor(() => expect(input.value).toBe('7   ')) // component trims leading space but allows trailing
      labels = optionsInList(menu).map(opt => opt.textContent)
    })

    it('excludes options not matching the entered text', async () => {
      expect(labels).not.toContain(labelForGrader('robin'))
    })

    it('include options exactly and partially matching the entered text', () => {
      expect(labels).toContain(labelForGrader('feeny'))
    })

    it('includes options partially matching the entered text', () => {
      expect(labels).toContain(labelForGrader('frizz'))
    })

    it('orders exact matches before partial ones', () => {
      expect(labels.slice(0, 2)).toEqual([labelForGrader('feeny'), labelForGrader('frizz')])
    })

    it('adds a custom grade when typed in and puts it last', () => {
      expect(labels.slice(-1)).toEqual([customLabel('7')])
    })
  })

  describe('when entered text partially matches grader names', () => {
    it('includes grades from graders whose names partially match the entered text', async () => {
      const {input, menu} = await mountAndClick(props)
      fireEvent.change(input, {target: {value: '   z   '}}) // includdes whitespace, but matches Miss Frizzle
      const labels = optionsInList(menu).map(opt => opt.textContent)
      expect(labels).toContain(labelForGrader('frizz'))
    })

    it('excludes grades from graders whose names do not match the entered text', async () => {
      const {input, menu} = await mountAndClick(props)
      fireEvent.change(input, {target: {value: 'mr'}}) // matches "Mr." and "Mrs."
      const labels = optionsInList(menu).map(opt => opt.textContent)
      expect(labels).not.toContain(labelForGrader('frizz')) // ... but it's "Miss" Frizzle
    })

    it('includes only options for matching grader names', async () => {
      const {input, menu} = await mountAndClick(props)
      fireEvent.change(input, {target: {value: 'f'}}) // matches Mr. Feeny and Miss Frizzle but no one else
      const labels = optionsInList(menu).map(opt => opt.textContent)
      expect(labels).toEqual(['frizz', 'feeny'].map(labelForGrader))
    })
  })

  describe('when entered text matches no grade nor grader name', () => {
    it('includes only the custom grade when the text is a valid score', async () => {
      const {input, menu} = await mountAndClick(props)
      fireEvent.change(input, {target: {value: '40'}})
      const labels = optionsInList(menu).map(opt => opt.textContent)
      expect(labels).toEqual([customLabel(40)])
    })

    it('shows only the "no selection" label when the text is not a valid score', async () => {
      const {input, menu} = await mountAndClick(props)
      fireEvent.change(input, {target: {value: 'nonsense'}})
      const labels = optionsInList(menu).map(opt => opt.textContent)
      expect(labels).toEqual([NO_SELECTION_LABEL])
    })

    it('includes the custom grade when called for by the name "custom"', async () => {
      const score = 38
      props.grades.teach = {
        grade: 'A++',
        graderId: 'teach',
        id: '4604',
        score,
        selected: true,
        studentId: '1111',
      }
      const {input, menu} = await mountAndClick(props)
      fireEvent.change(input, {target: {value: 'cust'}})
      const labels = optionsInList(menu).map(opt => opt.textContent)
      expect(labels).toEqual([customLabel(score)])
    })
  })

  describe('miscellaneous UI checks', () => {
    it('allows selection by filter then arrow down and enter', async () => {
      const onSelect = jest.fn()
      const {input} = await mountAndClick({...props, onSelect})
      fireEvent.change(input, {target: {value: 'mr.'}}) // matches Mr. Keating and Mr. Feeny
      fireEvent.keyDown(input, {keyCode: 40}) // downarrow
      fireEvent.keyDown(input, {keyCode: 13}) // enter
      await waitForMenuClosed(input)
      expect(onSelect).toHaveBeenCalledWith(props.grades.robin)
    })

    it('does not make the callback if the selection has not changed', async () => {
      props.grades.robin.selected = true
      const onSelect = jest.fn()
      const {input} = await mountAndClick({...props, onSelect})
      fireEvent.keyDown(input, {keyCode: 13}) // enter
      await waitForMenuClosed(input)
      expect(onSelect).not.toHaveBeenCalled()
    })

    it('closes the menu and makes no callback if escape is pressed during selection', async () => {
      const onSelect = jest.fn()
      const {input} = await mountAndClick({...props, onSelect})
      fireEvent.keyDown(input, {keyCode: 40}) // downarrow
      fireEvent.keyDown(input, {keyCode: 40}) // downarrow
      fireEvent.keyUp(input, {keyCode: 27}) // escape
      await waitForMenuClosed(input)
      expect(onSelect).not.toHaveBeenCalled()
    })

    it('disables and skips over an un-selectable grader', async () => {
      props.graders[1].graderSelectable = false // disable 'robin'
      const onSelect = jest.fn()
      const {input, menu} = await mountAndClick({...props, onSelect})
      const opt = findOption(menu, labelForGrader('robin'))
      expect(opt.attributes.getNamedItem('aria-disabled').value).toBe('true')
      fireEvent.change(input, {target: {value: 'mr.'}}) // matches robin and feeny
      fireEvent.keyDown(input, {keyCode: 40}) // downarrow should skip over disabled robin and land on feeny
      fireEvent.keyDown(input, {keyCode: 13}) // enter
      await waitForMenuClosed(input)
      expect(onSelect).toHaveBeenCalledWith(props.grades.feeny)
    })
  })
})
