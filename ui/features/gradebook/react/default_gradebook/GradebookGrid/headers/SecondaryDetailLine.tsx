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
import {Text} from '@instructure/ui-text'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('gradebook')

type SecondaryDetailLineProps = {
  assignment: {
    anonymizeStudents: boolean
    pointsPossible?: number
    published: boolean
    postManually?: boolean
  }
}

function SecondaryDetailLine(props: SecondaryDetailLineProps) {
  const anonymous = props.assignment.anonymizeStudents
  const unpublished = !props.assignment.published

  if (anonymous || unpublished) {
    return (
      <span className="Gradebook__ColumnHeaderDetailLine Gradebook__ColumnHeaderDetail--secondary">
        <Text color="danger" size="x-small" transform="uppercase" weight="bold">
          {unpublished ? I18n.t('Unpublished') : I18n.t('Anonymous')}
        </Text>
      </span>
    )
  }

  const pointsPossible = I18n.n(props.assignment.pointsPossible || 0)

  return (
    <span className="Gradebook__ColumnHeaderDetailLine Gradebook__ColumnHeaderDetail--secondary">
      <span className="assignment-points-possible">
        <Text weight="normal" fontStyle="normal" size="x-small">
          {I18n.t('Out of %{pointsPossible}', {pointsPossible})}
        </Text>
      </span>

      {props.assignment.postManually && (
        <span>
          &nbsp;
          <Text size="x-small" transform="uppercase" weight="bold">
            {I18n.t('Manual')}
          </Text>
        </span>
      )}
    </span>
  )
}

export default SecondaryDetailLine
