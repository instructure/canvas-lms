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

import React from 'react'
import {PlatformUiProvider} from '@instructure/platform-provider'
import {LearningAgentLauncher} from '@instructure/platform-learning-agent-launcher'
import {platformExecuteQuery} from '@canvas/graphql'
import {ErrorBoundary} from '@instructure/platform-error-boundary'

const LearningAgentButton = () => (
  <ErrorBoundary errorComponent={<></>}>
    <PlatformUiProvider
      executeQuery={platformExecuteQuery}
      locale={window.ENV.LOCALE ?? 'en'}
      timezone={window.ENV.TIMEZONE ?? 'UTC'}
      currentUserId={window.ENV.current_user_id ?? undefined}
    >
      <LearningAgentLauncher
        lmsSource="canvas-academic"
        lmsHasAthenaUser={window.ENV.ATHENA?.authenticated}
        learningAgentDomain={window.ENV.ATHENA?.launch_domain ?? undefined}
        learningAgentPath={window.ENV.ATHENA?.launch_path ?? undefined}
      />
    </PlatformUiProvider>
  </ErrorBoundary>
)

export default LearningAgentButton
