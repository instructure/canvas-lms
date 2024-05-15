/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import AssignmentGradeInput from '../index'
import {render, waitFor} from '@testing-library/react'

describe('GradebookGrid CompleteIncompleteGradeInput', () => {
  let props
  let ref
  let resolveClose
  let wrapper

  beforeEach(() => {
    ENV.GRADEBOOK_OPTIONS = {assignment_missing_shortcut: true}

    const assignment = {
      pointsPossible: 10,
    }
    const submission = {
      enteredGrade: null,
      enteredScore: null,
      excused: false,
      id: '2501',
    }

    props = {
      assignment,
      enterGradesAs: 'passFail',
      onMenuDismiss() {
        resolveClose()
      },
      submission,
    }
  })

  function mountComponent() {
    ref = React.createRef()
    wrapper = render(<AssignmentGradeInput {...props} ref={ref} />)
  }

  async function openAndClick(optionText) {
    await wrapper.getByRole('button').click()
    resolveClose = () => {}
    return wrapper.getByText(optionText).click()
  }

  function getTextValue() {
    const text = wrapper.find('.Grid__GradeCell__CompleteIncompleteValue').at(0)
    return text.getDOMNode().textContent
  }

  test('adds the CompleteIncompleteInput-suffix class to the container', () => {
    mountComponent()
    expect(
      wrapper.container.querySelector('.Grid__GradeCell__CompleteIncompleteInput')
    ).toBeInTheDocument()
  })

  test('renders a text container', () => {
    mountComponent()
    expect(
      wrapper.container.querySelectorAll('.Grid__GradeCell__CompleteIncompleteValue').length
    ).toBe(1)
  })

  test('optionally disables the menu button', () => {
    props.disabled = true
    mountComponent()
    expect(wrapper.getByRole('button')).toBeDisabled()
  })

  test('sets the value to "Complete" when the grade is "complete"', () => {
    props.submission = {...props.submission, enteredScore: 10, enteredGrade: 'complete'}
    mountComponent()
    expect(wrapper.getByText('Complete')).toBeInTheDocument()
  })

  test('sets the value to "Incomplete" when the grade is "incomplete"', () => {
    props.submission = {...props.submission, enteredScore: 0, enteredGrade: 'incomplete'}
    mountComponent()
    expect(wrapper.getByText('Incomplete')).toBeInTheDocument()
  })

  test('sets the value to "–" when the grade is null', () => {
    props.submission = {...props.submission, enteredScore: null, enteredGrade: null}
    mountComponent()
    expect(wrapper.getByText('–')).toBeInTheDocument()
  })

  test('sets the value to "Excused" when the submission is excused', () => {
    props.submission = {
      ...props.submission,
      enteredScore: null,
      enteredGrade: null,
      excused: true,
    }
    mountComponent()
    expect(wrapper.getByText('Excused')).toBeInTheDocument()
  })

  test('sets the value to the pending grade when present', () => {
    props.pendingGradeInfo = {excused: false, grade: 'complete', valid: true}
    mountComponent()
    expect(wrapper.getByText('Complete')).toBeInTheDocument()
  })

  describe('#gradeInfo', () => {
    function getGradeInfo() {
      return ref.current.gradeInfo
    }

    describe('when the submission is ungraded', () => {
      beforeEach(() => {
        mountComponent()
      })

      test('sets grade to null', () => {
        expect(getGradeInfo().grade).toBe(null)
      })

      test('sets score to null', () => {
        expect(getGradeInfo().score).toBe(null)
      })

      test('sets enteredAs to null', () => {
        expect(getGradeInfo().enteredAs).toBe(null)
      })

      test('sets excused to false', () => {
        expect(getGradeInfo().excused).toBe(false)
      })
    })

    describe('when the submission is graded', () => {
      beforeEach(() => {
        props.submission = {...props.submission, enteredGrade: 'complete', enteredScore: 10}
        mountComponent()
      })

      test('sets grade to the letter grade form of the entered grade', () => {
        expect(getGradeInfo().grade).toBe('complete')
      })

      test('sets score to the score form of the entered grade', () => {
        expect(getGradeInfo().score).toBe(10)
      })

      test('sets enteredAs to "passFail"', () => {
        expect(getGradeInfo().enteredAs).toBe('passFail')
      })

      test('sets excused to false', () => {
        expect(getGradeInfo().excused).toBe(false)
      })
    })

    describe('when the submission is excused', () => {
      beforeEach(() => {
        props.submission = {...props.submission, excused: true}
        mountComponent()
      })

      test('sets grade to null', () => {
        expect(getGradeInfo().grade).toBe(null)
      })

      test('sets score to null', () => {
        expect(getGradeInfo().score).toBe(null)
      })

      test('sets enteredAs to "excused"', () => {
        expect(getGradeInfo().enteredAs).toBe('excused')
      })

      test('sets excused to true', () => {
        expect(getGradeInfo().excused).toBe(true)
      })
    })

    describe('when the submission has a pending grade', () => {
      beforeEach(() => {
        props.pendingGradeInfo = {
          enteredAs: 'passFail',
          excused: false,
          grade: 'incomplete',
          score: 0,
          valid: true,
        }
        mountComponent()
      })

      test('sets grade to the grade of the pending grade', () => {
        expect(getGradeInfo().grade).toBe('incomplete')
      })

      test('sets score to the score of the pending grade', () => {
        expect(getGradeInfo().score).toBe(0)
      })

      test('sets enteredAs to the value of the pending grade', () => {
        expect(getGradeInfo().enteredAs).toBe('passFail')
      })

      test('sets excused to false', () => {
        expect(getGradeInfo().excused).toBe(false)
      })
    })

    describe('when an option in the menu is clicked', () => {
      beforeEach(() => {
        mountComponent()
      })

      test('sets enteredAs to "passFail"', async () => {
        await openAndClick('Open Complete/Incomplete menu')
        waitFor(() => expect(getGradeInfo().enteredAs).toBe('passFail'))
      })

      test('sets grade to "complete" when "Complete" is clicked', async () => {
        await openAndClick('Open Complete/Incomplete menu')
        waitFor(() => expect(getGradeInfo().grade).toBe('complete'))
      })

      test('sets score to points possible when "Complete" is clicked', async () => {
        await openAndClick('Open Complete/Incomplete menu')
        waitFor(() => expect(getGradeInfo().score).toBe(10))
      })

      test('sets excused to false when "Complete" is clicked', async () => {
        await openAndClick('Open Complete/Incomplete menu')
        waitFor(() => expect(getGradeInfo().excused).toBe(10))
      })

      test('sets grade to "incomplete" when "Incomplete" is clicked', async () => {
        await openAndClick('Open Complete/Incomplete menu')
        waitFor(() => expect(getGradeInfo().grade).toBe(10))
      })

      test('sets score to 0 when "Incomplete" is clicked', async () => {
        await openAndClick('Open Complete/Incomplete menu')
        waitFor(() => expect(getGradeInfo().score).toBe(10))
      })

      test('sets excused to false when "Incomplete" is clicked', async () => {
        await openAndClick('Open Complete/Incomplete menu')
        waitFor(() => expect(getGradeInfo().excused).toBe(10))
      })

      test('sets grade to null when "Ungraded" is clicked', async () => {
        await openAndClick('Ungraded')
        waitFor(() => expect(getGradeInfo().grade).toBe(10))
      })

      test('sets score to null when "Ungraded" is clicked', async () => {
        await openAndClick('Ungraded')
        waitFor(() => expect(getGradeInfo().score).toBe(10))
      })

      test('sets excused to false when "Ungraded" is clicked', async () => {
        await openAndClick('Ungraded')
        waitFor(() => expect(getGradeInfo().excused).toBe(10))
      })

      test('sets grade to null when "Excused" is clicked', async () => {
        await openAndClick('Excused')
        waitFor(() => expect(getGradeInfo().grade).toBe(10))
      })

      test('sets score to null when "Excused" is clicked', async () => {
        await openAndClick('Excused')
        waitFor(() => expect(getGradeInfo().score).toBe(10))
      })

      test('sets excused to true when "Excused" is clicked', async () => {
        await openAndClick('Excused')
        waitFor(() => expect(getGradeInfo().excused).toBe(10))
      })
    })
  })

  describe('#focus()', () => {
    test('sets focus on the button', () => {
      mountComponent()
      ref.current.focus()
      expect(wrapper.container.querySelector('button:focus')).toBeInTheDocument()
    })
  })

  describe('#handleKeyDown()', () => {
    const ENTER = {shiftKey: false, which: 13}
    test('returns false when pressing enter on the menu button', () => {
      mountComponent()
      const handleKeyDown = action => ref.current.handleKeyDown({...action})
      // return false to allow the popover menu to open
      wrapper.getByRole('button').focus()
      expect(handleKeyDown(ENTER)).toBe(false)
    })
  })

  describe('#hasGradeChanged()', () => {
    function hasGradeChanged() {
      return ref.current.hasGradeChanged()
    }

    test('returns false when a null grade is unchanged', () => {
      mountComponent()
      expect(hasGradeChanged()).toBe(false)
    })

    test('returns true when a different grade is clicked', async () => {
      props.submission = {...props.submission, enteredGrade: 'complete', enteredScore: 10}
      mountComponent()
      await openAndClick('Open Complete/Incomplete menu')
      waitFor(() => expect(hasGradeChanged()).toBe(true))
    })

    test('returns true when the submission becomes excused', async () => {
      props.submission = {...props.submission, enteredGrade: 'complete', enteredScore: 10}
      mountComponent()
      await openAndClick('Excused')
      waitFor(() => expect(hasGradeChanged()).toBe(true))
    })

    test('returns false when the same grade is clicked', async () => {
      props.submission = {...props.submission, enteredGrade: 'complete', enteredScore: 10}
      mountComponent()
      await openAndClick('Open Complete/Incomplete menu')
      waitFor(() => expect(hasGradeChanged()).toBe(true))
    })
  })

  describe('Complete/Incomplete Menu Items', () => {
    test('includes "Complete", "Incomplete", "Ungraded", and "Excused"', async () => {
      mountComponent()
      await wrapper.getByRole('button').click()
      waitFor(() => {
        expect(wrapper.getByText('Ungraded')).toBeInTheDocument()
        expect(wrapper.getByText('Excused')).toBeInTheDocument()
        expect(wrapper.getByText('Complete')).toBeInTheDocument()
        expect(wrapper.getByText('Incomplete')).toBeInTheDocument()
      })
    })

    test('sets the value to the selected option when clicked', async () => {
      mountComponent()
      await openAndClick('Open Complete/Incomplete menu')
      waitFor(() => expect(getTextValue()).toBe('Incomplete'))
    })

    test('set the value to "Excused" when clicked', async () => {
      mountComponent()
      await openAndClick('Excused')
      waitFor(() => expect(getTextValue()).toBe('Excused'))
    })
  })
})
