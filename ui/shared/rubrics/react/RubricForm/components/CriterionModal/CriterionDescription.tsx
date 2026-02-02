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

import {TextArea} from '@instructure/ui-text-area'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {useMemo} from 'react'

const I18n = createI18nScope('rubrics-criterion-modal')

type CriterionDescriptionProps = {
  criterionLongDescription: string
  setCriterionLongDescription: (value: string) => void
}

export const CriterionDescription = ({
  criterionLongDescription,
  setCriterionLongDescription,
}: CriterionDescriptionProps) => {
  const textareaValue = useMemo(() => {
    return (criterionLongDescription || '').replace(/<br\/>/g, '')
  }, [criterionLongDescription])

  return (
    <View as="div" margin="0">
      <TextArea
        label={I18n.t('Criterion Description')}
        placeholder={I18n.t('Enter the description')}
        maxHeight="6.75rem"
        width={'100%'}
        value={textareaValue}
        onChange={e => setCriterionLongDescription(e.target.value)}
        data-testid="rubric-criterion-description-input"
      />
    </View>
  )
}
