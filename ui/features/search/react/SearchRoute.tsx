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

import {Portal} from '@instructure/ui-portal'
import {useParams} from 'react-router-dom'
import SearchApp from './SearchApp'
import EnhancedSmartSearch from './enhanced_ui/EnhancedSmartSearch'
import {useEffect} from 'react'
import CanvasAiInformation from '@canvas/instui-bindings/react/AiInformation'
import {useScope as createI18nScope} from '@canvas/i18n'
import {theme} from '@instructure/canvas-theme'
import {Avatar} from '@instructure/ui-avatar'
import {createRoot} from 'react-dom/client'

const I18n = createI18nScope('SmartSearch')

export function Component(): JSX.Element | null {
  const {courseId} = useParams()

  useEffect(() => {
    const aiInformation = (
      <CanvasAiInformation
        featureName={I18n.t('IgniteAI Search')}
        modelName={I18n.t('Cohere Embed Multilingual')}
        isTrainedWithUserData={false}
        dataSharedWithModel={I18n.t('Course')}
        dataSharedWithModelDescription={I18n.t(
          'Course content is indexed by the model and then stored in the Canvas database.',
        )}
        dataRetention={I18n.t('Data is not stored or reused by the model,')}
        dataLogging={I18n.t('Does Not Log Data')}
        regionsSupported={I18n.t('US, Canada, EMEA, APAC, LATAM')}
        isPIIExposed={false}
        isPIIExposedDescription={I18n.t(
          'PII in course content may be indexed, but no PII is intentionally sent to the model',
        )}
        isFeatureBehindSetting={true}
        isHumanInTheLoop={true}
        expectedRisks={I18n.t(
          'Search results may be incorrectly sorted or may not be relevant to the search term',
        )}
        intendedOutcomes={I18n.t(
          'Students are able to quickly find answers to questions, and instructors are able to quickly navigate their courses.',
        )}
        permissionsLevel={2}
        triggerButton={
          <Avatar
            as="button"
            themeOverride={{
              color: theme.colors.primitives.grey125,
              borderColor: theme.colors.primitives.grey125,
            }}
            size="x-small"
            name={I18n.t('Artificial Intelligence')}
          />
        }
      />
    )
    const aiInfoElement = document.getElementById('ai-information-mount')
    if (aiInfoElement) {
      const root = createRoot(aiInfoElement)
      root.render(aiInformation)
    }
  }, [])

  const mountPoint = document.getElementById('search_app')
  if (mountPoint === null) {
    console.error('Cannot render SearchRoute, container is missing')
    return null
  }

  if (ENV.enhanced_ui_enabled) {
    return (
      <Portal open={true} mountNode={mountPoint}>
        <EnhancedSmartSearch courseId={courseId ?? ''} />
      </Portal>
    )
  }
  return (
    <Portal open={true} mountNode={mountPoint}>
      <SearchApp courseId={courseId} />
    </Portal>
  )
}
