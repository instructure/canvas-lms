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
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'

const I18n = createI18nScope('rubrics-assessment')

export const SelfAssessmentInstructions = () => {
  return (
    <Flex data-testid="rubric-self-assessment-instructions">
      <Flex.Item shouldGrow={true} padding="medium small">
        <div
          style={{
            position: 'relative',
            padding: '22px 18px',
            backgroundColor: '#F3F9F6',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            boxShadow: '0px 3px 6px 0px #00000029',
            borderRadius: '4px',
          }}
        >
          <Text weight="bold">{I18n.t('How well did you do?')}</Text>
          <Text>{I18n.t('Evaluate your work as you believe your instructor would.')}</Text>
          <Text>{I18n.t('Keep in mind that your instructor can review your self-assessment.')}</Text>

          <div
            style={{
              position: 'absolute',
              bottom: '-10px',
              left: '20px',
              width: '0',
              height: '0',
              borderLeft: '10px solid transparent',
              borderRight: '10px solid transparent',
              borderTop: '10px solid #F3F9F6',
            }}
          />
        </div>
      </Flex.Item>
    </Flex>
  )
}
