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

import {useScope as createI18nScope} from '@canvas/i18n'
import {Heading} from '@instructure/ui-heading'
import {Responsive} from '@instructure/ui-responsive'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import CalculationMethodContent from '@canvas/grading/CalculationMethodContent'
import type {GetRubricOutcomeQuery} from '@canvas/graphql/codegen/graphql'
import OutcomeContextTag from '@canvas/outcome-context-tag'

const I18n = createI18nScope('rubrics-assessment-outcome')

type OutcomePopoverDisplayProps = {
  outcome: GetRubricOutcomeQuery['learningOutcome']
}
export const OutcomePopoverDisplay = ({outcome}: OutcomePopoverDisplayProps) => {
  if (!outcome) {
    return
  }

  const hasDisplayName = outcome.displayName && outcome.displayName.length > 0
  const displayName = hasDisplayName ? outcome.displayName : outcome.title

  const calculationMethodContent = new CalculationMethodContent({
    calculation_method: outcome.calculationMethod,
    calculation_int: outcome.calculationInt,
    is_individual_outcome: true,
    mastery_points: outcome.masteryPoints,
  }).present()

  const {friendlyCalculationMethod, exampleText} = calculationMethodContent ?? {}

  return (
    <Responsive
      match="media"
      query={{
        compact: {maxWidth: '50rem'},
        fullWidth: {minWidth: '50rem'},
        large: {minWidth: '66.5rem'},
      }}
    >
      {(_props, matches) => {
        const isFullWidth = matches?.includes('fullWidth') ?? false
        const maxWidth = isFullWidth ? '600px' : '300px'

        return (
          <View as="div" display="block" data-testid="outcome-popover-display" maxWidth={maxWidth}>
            <Heading
              level="h3"
              as="h3"
              margin="x-small 0"
              data-testid="outcome-popover-display-name"
            >
              {displayName}
            </Heading>
            {hasDisplayName && (
              <Heading level="h4" as="h4" margin="x-small 0" data-testid="outcome-popover-title">
                {outcome.title}
              </Heading>
            )}
            <View
              as="div"
              data-testid="outcome-popover-display-content-description"
              dangerouslySetInnerHTML={{__html: outcome.description ?? ''}}
            />
            <OutcomeContextTag
              outcomeContextType={outcome.contextType ?? undefined}
              outcomeContextId={outcome.contextId ?? undefined}
              margin="0 0 x-small 0"
            />
            {friendlyCalculationMethod && exampleText && (
              <>
                <View as="hr" />
                <Flex as="div" width="100%" gap="medium" wrap={isFullWidth ? 'no-wrap' : 'wrap'}>
                  <Flex.Item align="start">
                    <Heading level="h4" as="h4">
                      {I18n.t('Calculation Method')}
                    </Heading>

                    <Text data-testid="outcome-popover-display-content-calculation-method">
                      {friendlyCalculationMethod}
                    </Text>
                  </Flex.Item>
                  <Flex.Item shouldGrow shouldShrink align="start">
                    <View as="div">
                      <Heading level="h4" as="h4">
                        {I18n.t('Example')}
                      </Heading>
                      <View as="div">
                        <Text
                          wrap="break-word"
                          data-testid="outcome-popover-display-content-example"
                        >
                          {exampleText}
                        </Text>
                      </View>
                    </View>
                  </Flex.Item>
                </Flex>
              </>
            )}
          </View>
        )
      }}
    </Responsive>
  )
}
