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
import {View} from '@instructure/ui-view'
import {Alert} from '@instructure/ui-alerts'
import {useScope as useI18nScope} from '@canvas/i18n'

import {
  gradingSchemeIsValid,
  rowNamesAreValid,
  rowDataIsValid,
  rowDataIsValidNumbers,
} from './validations/gradingSchemeValidations'
import type {GradingSchemeDataRow} from '@instructure/grading-utils'

const I18n = useI18nScope('GradingSchemes')

export interface ComponentProps {
  formData: {
    title: string
    data: GradingSchemeDataRow[]
    scalingFactor: number
    pointsBased: boolean
  }
  onClose: () => any
}

export const GradingSchemeValidationAlert: React.FC<ComponentProps> = ({onClose, formData}) => {
  const isValid = gradingSchemeIsValid(formData)

  return (
    <View
      elementRef={current => {
        if (current instanceof HTMLDivElement) {
          current.scrollIntoView()
          current.focus()
        }
      }}
    >
      <Alert
        variant={isValid ? 'success' : 'error'}
        margin="x-small 0"
        renderCloseButtonLabel="Close"
        hasShadow={false}
        onDismiss={onClose}
      >
        {gradingSchemeIsValid(formData) ? (
          // grading scheme did initially have validation error(s), but errors have since been corrected
          <>{I18n.t('Looks great!')}</>
        ) : !rowDataIsValidNumbers(formData) ? (
          <>
            {formData.pointsBased ? (
              <>
                {I18n.t(
                  "Range must be a valid number. Cannot have negative numbers or numbers that are greater than the upper points range. Fix the ranges and try clicking 'Save' again."
                )}
              </>
            ) : (
              <>
                {I18n.t(
                  "Range must be a valid number. Cannot have negative numbers or numbers that are greater than 100. Fix the ranges and try clicking 'Save' again."
                )}
              </>
            )}
          </>
        ) : !rowDataIsValid(formData) ? (
          <>
            {I18n.t(
              "Cannot have overlapping or empty ranges. Fix the ranges and try clicking 'Save' again."
            )}
          </>
        ) : !rowNamesAreValid(formData) ? (
          <>
            {I18n.t(
              "Cannot have duplicate or empty row names. Fix the names and try clicking 'Save' again."
            )}
          </>
        ) : !formData.title ? (
          <>
            {I18n.t("Grading Scheme Name is required. Add a name and try clicking 'Save' again.")}
          </>
        ) : (
          <>{I18n.t('Invalid grading scheme')}</>
        )}
      </Alert>
    </View>
  )
}
