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
import {render, fireEvent} from '@testing-library/react'

import GradeOverrideEntry from '@canvas/grading/GradeEntry/GradeOverrideEntry'
import {ApiCallStatus} from '@canvas/do-fetch-api-effect/apiRequest'
import {TotalGradeOverrideTray, type TotalGradeOverrideTrayProps} from '../TotalGradeOverrideTray'
import useStore from '../../stores'
import * as FinalGradeOverrideHooks from '../../hooks/useFinalGradeOverrideCustomStatus'

describe('TotalGradeOverrideTray Tests', () => {
  const navigateUp = jest.fn()
  const navigateDown = jest.fn()
  const handleDismiss = jest.fn()
  const handleOnGradeChange = jest.fn()
  const getComponent = (props: Partial<TotalGradeOverrideTrayProps> = {}) => {
    const trayProps: TotalGradeOverrideTrayProps = {
      customGradeStatuses: [
        {id: '1', color: '#000000', name: 'Custom Status 1'},
        {id: '2', color: '#FFFFFF', name: 'Custom Status 2'},
        {id: '3', color: '#EEEEEE', name: 'Custom Status 3'},
      ],
      handleDismiss,
      handleOnGradeChange,
      selectedGradingPeriodId: '0',
      navigateDown,
      navigateUp,
      ...props,
    }

    return render(<TotalGradeOverrideTray {...trayProps} />)
  }

  beforeEach(() => {
    const gradeEntry = new GradeOverrideEntry({
      gradingScheme: null,
    })

    useStore.setState({
      finalGradeOverrideTrayProps: {
        gradeEntry,
        isFirstStudent: false,
        isLastStudent: false,
        isOpen: true,
        studentInfo: {
          avatarUrl: 'https://canvas.instructure.com/images/messages/avatar-50.png',
          enrollmentId: '1111',
          gradesUrl: 'https://canvas.instructure.com/courses/1/grades/1',
          id: '1',
          name: 'Test Student',
        },
      },
      finalGradeOverrides: {
        '1': {
          courseGrade: {
            percentage: 0.5,
            customGradeStatusId: '1',
          },
          gradingPeriodGrades: {
            '1': {
              percentage: 0.5,
              customGradeStatusId: '2',
            },
            '2': {
              percentage: 0.5,
            },
          },
        },
      },
    })
  })

  afterEach(() => {
    jest.resetAllMocks()
  })

  describe('student carousel tests', () => {
    it('should call navigateUp when the left arrow is clicked', () => {
      const {getByTestId} = getComponent()
      const upArrow = getByTestId('left-arrow-button')

      fireEvent.click(upArrow)

      expect(navigateUp).toHaveBeenCalled()
    })

    it('should call navigateDown when the right arrow is clicked', () => {
      const {getByTestId} = getComponent()
      const downArrow = getByTestId('right-arrow-button')

      fireEvent.click(downArrow)

      expect(navigateDown).toHaveBeenCalled()
    })

    it('does not render the left arrow when the student is the first student', () => {
      useStore.setState({
        finalGradeOverrideTrayProps: {
          ...useStore.getState().finalGradeOverrideTrayProps,
          isFirstStudent: true,
        },
      })
      const {queryByTestId} = getComponent()
      const upArrow = queryByTestId('left-arrow-button')

      expect(upArrow).toBeNull()
    })

    it('does not render the right arrow when the student is the last student', () => {
      useStore.setState({
        finalGradeOverrideTrayProps: {
          ...useStore.getState().finalGradeOverrideTrayProps,
          isLastStudent: true,
        },
      })
      const {queryByTestId} = getComponent()
      const downArrow = queryByTestId('right-arrow-button')

      expect(downArrow).toBeNull()
    })

    it('renders the student name', () => {
      const {getByText} = getComponent()
      const studentName = getByText('Test Student')

      expect(studentName).toBeInTheDocument()
    })
  })

  // EVAL-3907 - remove or rewrite to remove spies on imports
  describe.skip('radio input tests', () => {
    it('renders each radio input', () => {
      const {getByLabelText} = getComponent()
      const noneRadio = getByLabelText('None')
      const radio1 = getByLabelText('Custom Status 1')
      const radio2 = getByLabelText('Custom Status 2')
      const radio3 = getByLabelText('Custom Status 3')

      expect(noneRadio).toBeInTheDocument()
      expect(noneRadio).not.toBeDisabled()
      expect(radio1).toBeInTheDocument()
      expect(radio1).not.toBeDisabled()
      expect(radio2).toBeInTheDocument()
      expect(radio2).not.toBeDisabled()
      expect(radio3).toBeInTheDocument()
      expect(radio3).not.toBeDisabled()
    })

    it('does not render radio inputs when there are no custom statuses', () => {
      const {queryByLabelText} = getComponent({customGradeStatuses: []})
      const noneRadio = queryByLabelText('None')
      const radio1 = queryByLabelText('Custom Status 1')
      const radio2 = queryByLabelText('Custom Status 2')
      const radio3 = queryByLabelText('Custom Status 3')

      expect(noneRadio).toBeNull()
      expect(radio1).toBeNull()
      expect(radio2).toBeNull()
      expect(radio3).toBeNull()
    })

    it('renders the correct radio input as checked', () => {
      const {getByLabelText} = getComponent()
      const radio1 = getByLabelText('Custom Status 1')

      expect(radio1).toBeChecked()
    })

    it('renders the correct radio as checked when selectedGradingPeriodId is set', () => {
      const {getByLabelText} = getComponent({selectedGradingPeriodId: '1'})
      const radio2 = getByLabelText('Custom Status 2')

      expect(radio2).toBeChecked()
    })

    it('renders None as checked when the grading period does not have a status', () => {
      const {getByLabelText} = getComponent({selectedGradingPeriodId: '2'})
      const radio = getByLabelText('None')

      expect(radio).toBeChecked()
    })

    it('calls setFinalGradeOverride when a radio input is clicked', async () => {
      const saveFinalOverrideCustomStatusMock = jest.fn()
      jest.spyOn(FinalGradeOverrideHooks, 'useFinalGradeOverrideCustomStatus').mockReturnValue({
        saveFinalOverrideCustomStatus: saveFinalOverrideCustomStatusMock,
        saveCallStatus: ApiCallStatus.COMPLETED,
      })

      const {getByLabelText} = getComponent()
      const radio = getByLabelText('Custom Status 3')

      fireEvent.click(radio)

      expect(saveFinalOverrideCustomStatusMock).toHaveBeenCalledWith('3', '1111', null)

      await new Promise(resolve => setTimeout(resolve, 0))
      const updatedFinalGradeOverrides = useStore.getState().finalGradeOverrides
      expect(updatedFinalGradeOverrides['1'].courseGrade?.customGradeStatusId).toEqual('3')
    })

    it('calls setFinalGradeOverride when a radio input is clicked with null finalGradeOverride', async () => {
      useStore.setState({
        finalGradeOverrides: {},
      })

      const saveFinalOverrideCustomStatusMock = jest.fn()
      jest.spyOn(FinalGradeOverrideHooks, 'useFinalGradeOverrideCustomStatus').mockReturnValue({
        saveFinalOverrideCustomStatus: saveFinalOverrideCustomStatusMock,
        saveCallStatus: ApiCallStatus.COMPLETED,
      })

      const {getByLabelText} = getComponent()
      const radio = getByLabelText('Custom Status 3')

      fireEvent.click(radio)

      expect(saveFinalOverrideCustomStatusMock).toHaveBeenCalledWith('3', '1111', null)

      await new Promise(resolve => setTimeout(resolve, 0))
      const updatedFinalGradeOverrides = useStore.getState().finalGradeOverrides
      expect(updatedFinalGradeOverrides['1'].courseGrade?.customGradeStatusId).toEqual('3')
    })

    it('calls setFinalGradeOverride when a radio input is clicked with selectedGradingPeriodId', async () => {
      const saveFinalOverrideCustomStatusMock = jest.fn()
      jest.spyOn(FinalGradeOverrideHooks, 'useFinalGradeOverrideCustomStatus').mockReturnValue({
        saveFinalOverrideCustomStatus: saveFinalOverrideCustomStatusMock,
        saveCallStatus: ApiCallStatus.COMPLETED,
      })

      const {getByLabelText} = getComponent({selectedGradingPeriodId: '2'})
      const radio = getByLabelText('Custom Status 1')

      fireEvent.click(radio)

      expect(saveFinalOverrideCustomStatusMock).toHaveBeenCalledWith('1', '1111', '2')

      await new Promise(resolve => setTimeout(resolve, 0))
      const updatedFinalGradeOverrides = useStore.getState().finalGradeOverrides
      expect(
        updatedFinalGradeOverrides['1'].gradingPeriodGrades?.['2']?.customGradeStatusId
      ).toEqual('1')
    })

    it('calls setFinalGradeOverride when a radio input is clicked with selectedGradingPeriodId and null finalGradeOverride', async () => {
      useStore.setState({
        finalGradeOverrides: {},
      })

      const saveFinalOverrideCustomStatusMock = jest.fn()
      jest.spyOn(FinalGradeOverrideHooks, 'useFinalGradeOverrideCustomStatus').mockReturnValue({
        saveFinalOverrideCustomStatus: saveFinalOverrideCustomStatusMock,
        saveCallStatus: ApiCallStatus.COMPLETED,
      })

      const {getByLabelText} = getComponent({selectedGradingPeriodId: '2'})
      const radio = getByLabelText('Custom Status 1')

      fireEvent.click(radio)

      expect(saveFinalOverrideCustomStatusMock).toHaveBeenCalledWith('1', '1111', '2')

      await new Promise(resolve => setTimeout(resolve, 0))
      const updatedFinalGradeOverrides = useStore.getState().finalGradeOverrides
      expect(
        updatedFinalGradeOverrides['1'].gradingPeriodGrades?.['2']?.customGradeStatusId
      ).toEqual('1')
    })

    it('calls setFinalGradeOverride when a radio input is clicked with selectedGradingPeriodId and null finalGradeOverride but valid course override', async () => {
      useStore.setState({
        finalGradeOverrides: {
          '1': {
            courseGrade: {
              percentage: 0.5,
              customGradeStatusId: '1',
            },
          },
        },
      })

      const saveFinalOverrideCustomStatusMock = jest.fn()
      jest.spyOn(FinalGradeOverrideHooks, 'useFinalGradeOverrideCustomStatus').mockReturnValue({
        saveFinalOverrideCustomStatus: saveFinalOverrideCustomStatusMock,
        saveCallStatus: ApiCallStatus.COMPLETED,
      })

      const {getByLabelText} = getComponent({selectedGradingPeriodId: '2'})
      const radio = getByLabelText('Custom Status 1')

      fireEvent.click(radio)

      expect(saveFinalOverrideCustomStatusMock).toHaveBeenCalledWith('1', '1111', '2')

      await new Promise(resolve => setTimeout(resolve, 0))
      const updatedFinalGradeOverrides = useStore.getState().finalGradeOverrides
      expect(
        updatedFinalGradeOverrides['1'].gradingPeriodGrades?.['2']?.customGradeStatusId
      ).toEqual('1')
    })

    it('calls handleDismiss with true when the button is clicked', () => {
      const {getByText} = getComponent()
      const cancelButton = getByText('Close total grade override tray')

      fireEvent.click(cancelButton)

      expect(handleDismiss).toHaveBeenCalledWith(true)
    })

    it('disables a radio input when custom status allow_final_grade_value is false and there is an override score', () => {
      const {getByLabelText} = getComponent({
        customGradeStatuses: [
          {
            id: '1',
            color: '#000000',
            name: 'Custom Status 1',
            allow_final_grade_value: false,
          },
        ],
      })
      const radio = getByLabelText('Custom Status 1')

      expect(radio).toBeDisabled()
    })

    it('does not disable a radio input when custom status allow_final_grade_value is false and there is no override score', () => {
      useStore.setState({
        finalGradeOverrides: {},
      })
      const {getByLabelText} = getComponent({
        customGradeStatuses: [
          {
            id: '1',
            color: '#000000',
            name: 'Custom Status 1',
            allow_final_grade_value: false,
          },
        ],
      })
      const radio = getByLabelText('Custom Status 1')

      expect(radio).not.toBeDisabled()
    })
  })

  describe('grade override textbox tests', () => {
    it('correctly renders final grade override textbox value', () => {
      const {getByDisplayValue} = getComponent()
      const textbox = getByDisplayValue('0.5%')

      expect(textbox).toBeInTheDocument()
    })

    it('calls handleOnGradeChange when the textbox value changes', () => {
      const {getByDisplayValue} = getComponent()
      const textbox = getByDisplayValue('0.5%')

      fireEvent.change(textbox, {target: {value: '0.6%'}})
      fireEvent.blur(textbox)

      expect(handleOnGradeChange).toHaveBeenCalled()
      const args = handleOnGradeChange.mock.calls[0]
      const [studentId, gradeChanges] = args
      expect(studentId).toEqual('1')
      expect(gradeChanges.grade.percentage).toEqual(0.6)
    })

    it('disables textbox when selected custom status allow_final_grade_value is false', () => {
      const {getByRole} = getComponent({
        customGradeStatuses: [
          {
            id: '1',
            color: '#000000',
            name: 'Custom Status 1',
            allow_final_grade_value: false,
          },
        ],
      })
      const textbox = getByRole('textbox')

      expect(textbox).toBeDisabled()
    })

    it('does not disable textbox when selected custom status allow_final_grade_value is false and there is no override score', () => {
      useStore.setState({
        finalGradeOverrides: {},
      })
      const {getByRole} = getComponent({
        customGradeStatuses: [
          {
            id: '1',
            color: '#000000',
            name: 'Custom Status 1',
            allow_final_grade_value: false,
          },
        ],
      })
      const textbox = getByRole('textbox')

      expect(textbox).not.toBeDisabled()
    })

    it('does not disabled textbox when selected custom status allow_final_grade_value is true', () => {
      const {getByRole} = getComponent({
        customGradeStatuses: [
          {
            id: '1',
            color: '#000000',
            name: 'Custom Status 1',
            allow_final_grade_value: true,
          },
        ],
      })
      const textbox = getByRole('textbox')

      expect(textbox).not.toBeDisabled()
    })
  })
})
