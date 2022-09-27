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
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {TurnitinData} from '@canvas/assignments/graphql/student/TurnitinData'

const I18n = useI18nScope('assignments_2')
export default function OriginalityReport({originalityData}) {
  return (
    <View as="div">
      <span className="turnitin_score_container" data-testid="originality_report">
        <span className={'turnitin_score_container_caret ' + originalityData.state + '_score'} />
        <a
          href={originalityData.reportUrl}
          className={'turnitin_similarity_score ' + originalityData.state + '_score'}
          data-testid="originality_report_url"
          title={I18n.t('Similarity score -- %{state}', {state: originalityData.state})}
        >
          {originalityData.score}%
        </a>
      </span>
    </View>
  )
}

OriginalityReport.propTypes = {
  originalityData: TurnitinData.shape.isRequired,
}
