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

import React from 'react'
import {Flex} from '@instructure/ui-flex'
import {GradebookSettings} from '@canvas/outcomes/react/utils/constants'
import type {
  SecondaryInfoDisplay,
  DisplayFilter,
  ScoreDisplayFormat,
  OutcomeArrangement,
} from '@instructure/outcomes-ui/lib/util/gradebook/constants'
import {SecondaryInfoSelector} from '@instructure/outcomes-ui/es/components/Gradebook/toolbar/SettingsTray/SecondaryInfoSelector'
import {DisplayFilterSelector} from '@instructure/outcomes-ui/es/components/Gradebook/toolbar/SettingsTray/DisplayFilterSelector'
import {ScoreDisplayFormatSelector} from '@instructure/outcomes-ui/es/components/Gradebook/toolbar/SettingsTray/ScoreDisplayFormatSelector'
import {OutcomeArrangementSelector} from '@instructure/outcomes-ui/es/components/Gradebook/toolbar/SettingsTray/OutcomeArrangementSelector'

export interface SettingsTrayContentProps {
  settings: GradebookSettings
  onChange: (settings: GradebookSettings) => void
}

export const SettingsTrayContent: React.FC<SettingsTrayContentProps> = ({settings, onChange}) => {
  return (
    <Flex direction="column" padding="small medium" alignItems="stretch" gap="medium">
      <SecondaryInfoSelector
        value={settings.secondaryInfoDisplay}
        onChange={(info: SecondaryInfoDisplay) =>
          onChange({...settings, secondaryInfoDisplay: info})
        }
      />
      <DisplayFilterSelector
        values={settings.displayFilters}
        onChange={(filters: DisplayFilter[]) => onChange({...settings, displayFilters: filters})}
      />
      <ScoreDisplayFormatSelector
        value={settings.scoreDisplayFormat}
        onChange={(format: ScoreDisplayFormat) =>
          onChange({...settings, scoreDisplayFormat: format})
        }
      />
      <OutcomeArrangementSelector
        value={settings.outcomeArrangement}
        onChange={(arrangement: OutcomeArrangement) =>
          onChange({...settings, outcomeArrangement: arrangement})
        }
      />
    </Flex>
  )
}
