/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {useScope as createI18nScope} from '@canvas/i18n'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import type {RubricRating} from '@canvas/rubrics/react/types/rubric'
import {possibleString, possibleStringRange} from '@canvas/rubrics/react/Points'
import {escapeNewLineText, rangingFrom} from '@canvas/rubrics/react/RubricAssessment'
import {Text} from '@instructure/ui-text'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {View} from '@instructure/ui-view'
import '../drag-and-drop/styles.css'

const I18n = createI18nScope('rubrics-criteria-row')

type RatingScaleAccordionProps = {
  hidePoints: boolean
  ratings: RubricRating[]
  criterionUseRange: boolean
  isGenerated?: boolean
  addExtraBottomSpacing?: boolean
}
export const RatingScaleAccordion = ({
  hidePoints,
  ratings,
  criterionUseRange,
  isGenerated = false,
  addExtraBottomSpacing = false,
}: RatingScaleAccordionProps) => {
  return (
    <View as="div" margin={`small 0 ${addExtraBottomSpacing ? 'small' : '0'} 0`}>
      <ToggleDetails
        data-testid="criterion-row-rating-accordion"
        defaultExpanded={isGenerated}
        summary={`${I18n.t('Rating Scale: %{ratingsLength}', {ratingsLength: ratings.length})}`}
      >
        <table className="rating-scale-table" width="100%">
          <caption>
            <ScreenReaderContent>{I18n.t('Rating Scale')}</ScreenReaderContent>
          </caption>
          <thead>
            <tr>
              <th style={{width: '2.5rem'}}>
                <ScreenReaderContent>{I18n.t('Scale')}</ScreenReaderContent>
              </th>
              <th style={{width: '7rem'}}>
                <ScreenReaderContent>{I18n.t('Rating')}</ScreenReaderContent>
              </th>
              <th>
                <ScreenReaderContent>{I18n.t('Description')}</ScreenReaderContent>
              </th>
              {!hidePoints && (
                <th style={{width: '5rem', paddingLeft: '1.5rem'}}>
                  <ScreenReaderContent>{I18n.t('Points')}</ScreenReaderContent>
                </th>
              )}
            </tr>
          </thead>
          <tbody>
            {ratings.map((rating, index) => {
              const scale = ratings.length - (index + 1)
              const min = criterionUseRange ? rangingFrom(ratings, index) : undefined
              return (
                <tr
                  key={`rating-scale-item-${rating.id}-${index}`}
                  data-testid="rating-scale-accordion-item"
                  style={{verticalAlign: 'top'}}
                >
                  <td>{scale}</td>
                  <td>{rating.description}</td>
                  <td>
                    <Text
                      dangerouslySetInnerHTML={escapeNewLineText(rating.longDescription)}
                      themeOverride={{paragraphMargin: 0}}
                    />
                  </td>
                  {!hidePoints && (
                    <td style={{paddingLeft: '1.5rem'}}>
                      <Text>
                        {min != null
                          ? possibleStringRange(min, rating.points)
                          : possibleString(rating.points)}
                      </Text>
                    </td>
                  )}
                </tr>
              )
            })}
          </tbody>
        </table>
      </ToggleDetails>
    </View>
  )
}
