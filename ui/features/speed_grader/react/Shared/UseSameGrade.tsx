/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {useScope as createI18nScope} from '@canvas/i18n'
import {Link} from '@instructure/ui-link'

const I18n = createI18nScope('speed_grader')

type Props = {
  onUseSameGrade: () => void
}

export const UseSameGrade = ({onUseSameGrade}: Props) => {
  return (
    <Link
      isWithinText={false}
      as="button"
      onClick={() => onUseSameGrade()}
      data-testid="use-same-grade-link"
    >
      {I18n.t('Use this same grade for the resubmission')}
    </Link>
  )
}
