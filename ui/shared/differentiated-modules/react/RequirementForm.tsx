/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {FormFieldGroup} from '@instructure/ui-form-field'
import {Button} from '@instructure/ui-buttons'
// @ts-expect-error -- remove once on InstUI 8
import {IconAddLine} from '@instructure/ui-icons'
import RequirementCountInput from './RequirementCountInput'
import RequirementSelector from './RequirementSelector'
import type {Requirement, ModuleItem} from './types'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('differentiated_modules')

export interface RequirementFormProps {
  requirements: Requirement[]
  requirementCount: 'all' | 'one'
  requireSequentialProgress: boolean
  moduleItems: ModuleItem[]
  onChangeRequirementCount: (type: 'all' | 'one') => void
  onToggleSequentialProgress: () => void
  onAddRequirement: (requirement: Requirement) => void
  onDropRequirement: (index: number) => void
  onUpdateRequirement: (requirement: Requirement, index: number) => void
}

export default function RequirementForm({
  requirements,
  requirementCount,
  requireSequentialProgress,
  moduleItems,
  onChangeRequirementCount,
  onToggleSequentialProgress,
  onAddRequirement,
  onDropRequirement,
  onUpdateRequirement,
}: RequirementFormProps) {
  return (
    <FormFieldGroup
      description={I18n.t('Requirements')}
      layout="stacked"
      data-testid="requirement-form"
    >
      {requirements.length > 0 && (
        <RequirementCountInput
          requirementCount={requirementCount}
          requireSequentialProgress={requireSequentialProgress}
          onChangeRequirementCount={onChangeRequirementCount}
          onToggleSequentialProgress={onToggleSequentialProgress}
        />
      )}
      {requirements.map((requirement, index) => (
        <RequirementSelector
          key={requirement.name}
          requirement={requirement}
          moduleItems={moduleItems}
          onDropRequirement={onDropRequirement}
          onUpdateRequirement={onUpdateRequirement}
          index={index}
        />
      ))}
      <Button
        onClick={() => {
          onAddRequirement({
            ...moduleItems[0],
            type: 'view',
          } as Requirement)
        }}
        renderIcon={<IconAddLine />}
      >
        {I18n.t('Requirement')}
      </Button>
    </FormFieldGroup>
  )
}
