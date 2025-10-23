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

import AlertManager from '@canvas/alerts/react/AlertManager'
import ErrorBoundary from '@canvas/error-boundary'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import GenericErrorPage from '@canvas/generic-error-page'
import {useScope as createI18nScope} from '@canvas/i18n'
import React from 'react'
import {AIExperienceShowProps} from '../types'
import AIExperienceShow from './components/AIExperienceShow'

const I18n = createI18nScope('ai_experiences_show')

export const AIExperiencesShow: React.FC<AIExperienceShowProps> = props => {
  return (
    <ErrorBoundary
      errorComponent={
        <GenericErrorPage
          imageUrl={errorShipUrl}
          errorCategory={I18n.t('AI Experience Show Error Page')}
        />
      }
    >
      <AlertManager breakpoints={{}}>
        <AIExperienceShow aiExperience={props.aiExperience} />
      </AlertManager>
    </ErrorBoundary>
  )
}
