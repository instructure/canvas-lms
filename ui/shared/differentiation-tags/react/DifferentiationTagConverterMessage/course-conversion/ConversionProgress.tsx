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
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {ProgressBar} from '@instructure/ui-progress'
import {Alert} from '@instructure/ui-alerts'

const I18n = createI18nScope('differentiation_tags')

interface ConversionProgressProps {
  progress: number
}

const ConversionProgress = ({progress}: ConversionProgressProps) => {
  const jobMessage = I18n.t('Tag conversion in progress')

  return (
    <Alert
      variant="warning"
      hasShadow={false}
      margin="0 0 medium 0"
      data-testid="course-differentiation-tag-conversion-progress"
    >
      <Flex direction="column">
        <Text>{I18n.t('Course Tag Conversion Progress')}</Text>
        <ProgressBar
          size="small"
          margin="small 0 0 0"
          screenReaderLabel={jobMessage}
          valueNow={progress}
          valueMax={100}
          shouldAnimate={true}
          renderValue={({valueNow, valueMax}) => {
            return <Text>{Math.round((valueNow / valueMax) * 100)}%</Text>
          }}
          formatScreenReaderValue={({valueNow, valueMax}) => {
            return Math.round((valueNow / valueMax) * 100) + 'percent'
          }}
          data-testid="course-tag-conversion-progress-bar"
        />
      </Flex>
    </Alert>
  )
}

export default ConversionProgress
