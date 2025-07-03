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

import {TextInput} from '@instructure/ui-text-input'
import {useScope as createI18nScope} from '@canvas/i18n'
import {FormMessage} from '@instructure/ui-form-field'

const I18n = createI18nScope('rubrics-criterion-modal')

type CriterionNameProps = {
  isFullWidth: boolean
  criterionDescription: string
  criterionDescriptionErrorMessage: FormMessage[]
  setCriterionDescription: (value: string) => void
}
export const CriterionName = ({
  isFullWidth,
  criterionDescription,
  criterionDescriptionErrorMessage,
  setCriterionDescription,
}: CriterionNameProps) => {
  return (
    <TextInput
      renderLabel={I18n.t('Criterion Name')}
      placeholder={I18n.t('Enter the name')}
      display="inline-block"
      width={isFullWidth ? '20.75rem' : '100%'}
      value={criterionDescription ?? ''}
      messages={criterionDescriptionErrorMessage}
      onChange={(_e, value) => setCriterionDescription(value)}
      data-testid="rubric-criterion-name-input"
    />
  )
}
