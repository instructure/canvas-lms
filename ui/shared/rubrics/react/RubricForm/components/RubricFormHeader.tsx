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
import getLiveRegion from '@canvas/instui-bindings/react/liveRegion'
import {Alert} from '@instructure/ui-alerts'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'

const I18n = createI18nScope('rubrics-form')

type RubricFormHeaderProps = {
  header: string
  hideHeader: boolean
  isUnassessed: boolean
  canUpdateRubric: boolean
  saveError: boolean
}

export const RubricFormHeader = ({
  header,
  hideHeader,
  isUnassessed,
  canUpdateRubric,
  saveError,
}: RubricFormHeaderProps) => {
  return (
    <>
      {saveError && (
        <Flex.Item>
          <Alert
            variant="error"
            liveRegionPoliteness="polite"
            isLiveRegionAtomic={true}
            liveRegion={getLiveRegion}
            timeout={3000}
          >
            <Text weight="bold">{I18n.t('There was an error saving the rubric.')}</Text>
          </Alert>
        </Flex.Item>
      )}
      {!hideHeader && (
        <Flex.Item>
          <Heading level="h1" as="h1" themeOverride={{h1FontWeight: 700}}>
            {header}
          </Heading>
        </Flex.Item>
      )}
      {!canUpdateRubric && (
        <Flex.Item>
          <Alert variant="info" margin="medium 0 0 0" data-testid="rubric-cannot-update-alert">
            {I18n.t(
              'Rubrics cannot be modified once they have been used in more than one place. Any saved changes will create a new rubric.',
            )}
          </Alert>
        </Flex.Item>
      )}
      {!isUnassessed && canUpdateRubric && (
        <Flex.Item>
          <Alert variant="info" margin="medium 0 0 0" data-testid="rubric-limited-edit-mode-alert">
            {I18n.t(
              'This rubric has already been used for grading. Any changes made may impact existing student scores or grading data.',
            )}
          </Alert>
        </Flex.Item>
      )}
    </>
  )
}
