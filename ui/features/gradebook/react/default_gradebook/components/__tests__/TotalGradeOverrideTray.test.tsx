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
import {ApiCallStatus} from '@canvas/util/apiRequest'
import {TotalGradeOverrideTray, TotalGradeOverrideTrayProps} from '../TotalGradeOverrideTray'
import useStore from '../../stores'
import * as FinalGradeOverrideHooks from '../../hooks/useFinalGradeOverrideCustomStatus'

describe('TotalGradeOverrideTray Tests', () => {
  const navigateUp = jest.fn()
  const navigateDown = jest.fn()
  const getComponent = (props: Partial<TotalGradeOverrideTrayProps> = {}) => {
    const trayProps: TotalGradeOverrideTrayProps = {
      customGradeStatuses: [
        {id: '1', color: '#000000', name: 'Custom Status 1'},
        {id: '2', color: '#FFFFFF', name: 'Custom Status 2'},
        {id: '3', color: '#EEEEEE', name: 'Custom Status 3'},
      ],
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
      pointsBasedGradingSchemesFeatureEnabled: true,
    })
    const gradeInfo = gradeEntry.gradeInfoFromGrade({percentage: 88}, false)

    useStore.setState({
      finalGradeOverrideTrayProps: {
        gradeEntry,
        gradeInfo,
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

  describe('radio input tests', () => {
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

    it('renders radio inputs disabled when gradeInfo & gradeEntry are not set', () => {
      useStore.setState({
        finalGradeOverrideTrayProps: {
          ...useStore.getState().finalGradeOverrideTrayProps,
          gradeInfo: undefined,
          gradeEntry: undefined,
        },
      })
      const {getByLabelText} = getComponent()
      const noneRadio = getByLabelText('None')
      const radio1 = getByLabelText('Custom Status 1')
      const radio2 = getByLabelText('Custom Status 2')
      const radio3 = getByLabelText('Custom Status 3')

      expect(noneRadio).toBeDisabled()
      expect(radio1).toBeDisabled()
      expect(radio2).toBeDisabled()
      expect(radio3).toBeDisabled()
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
  })
})
