// @ts-nocheck
/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {Button} from '@instructure/ui-buttons'
import {Tooltip} from '@instructure/ui-tooltip'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {SimilarityScore} from '../../../../../../api.d' // !!! FIXME

import SimilarityIcon from '../../components/SimilarityIcon'

const I18n = useI18nScope('gradebook')

function tooltipText({similarityScore, status}) {
  if (status === 'error') {
    return I18n.t('Error submitting to plagiarism service')
  } else if (status === 'pending') {
    return I18n.t('Being processed by plagiarism service')
  }

  const formattedScore = I18n.n(similarityScore, {precision: 1})
  return I18n.t('%{similarityScore}% similarity score', {similarityScore: formattedScore})
}

type Props = {
  elementRef: (element: HTMLButtonElement | null) => void
  similarityInfo: SimilarityScore
}

export default function SimilarityIndicator({elementRef, similarityInfo}: Props) {
  const {similarityScore, status} = similarityInfo

  const Icon = () => <SimilarityIcon status={status} similarityScore={similarityScore} />

  return (
    <div className="Grid__GradeCell__OriginalityScore">
      <Tooltip placement="bottom" renderTip={tooltipText(similarityInfo)} color="primary">
        <Button
          elementRef={ref => {
            elementRef(ref as HTMLButtonElement | null)
          }}
          size="small"
          renderIcon={Icon}
          withBackground={false}
        />
      </Tooltip>
    </div>
  )
}
