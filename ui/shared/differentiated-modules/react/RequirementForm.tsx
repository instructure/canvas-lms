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

import React, {createRef, useEffect, useMemo, useRef, useState} from 'react'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {Button} from '@instructure/ui-buttons'
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
  const addRequirementButton = createRef<Button>()
  const internalLastAction = useRef<{action: 'add' | 'delete'; index: number} | null>(null)
  const [focus, setFocus] = useState<{
    type: 'dropdown' | 'button' | 'radio'
    index?: number
  } | null>()
  const availableModuleItems = useMemo(() => {
    const requirementIds = new Set(requirements.map(requirement => requirement.id))
    return moduleItems.filter(module => !requirementIds.has(module.id))
  }, [moduleItems, requirements])

  // This avoids re-focusing after re-renders
  // eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(() => {
    setFocus(null)
  })

  useEffect(() => {
    if (internalLastAction.current?.action === 'add' && requirements.length > 1) {
      setFocus({type: 'dropdown', index: requirements.length - 1})
    } else if (internalLastAction.current?.action === 'add' && requirements.length === 1) {
      setFocus({type: 'radio'})
    } else if (internalLastAction.current?.action === 'delete' && requirements.length > 0) {
      const deletedIndex = internalLastAction.current?.index
      setFocus({type: 'button', index: deletedIndex > 0 ? deletedIndex - 1 : 0})
    } else if (internalLastAction.current?.action === 'delete' && requirements.length === 0) {
      addRequirementButton.current?.focus()
    }
    internalLastAction.current = null
  }, [addRequirementButton, requirements.length])

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
          focus={focus?.type === 'radio'}
        />
      )}
      {requirements.map((requirement, index) => (
        <RequirementSelector
          // This is needed to keep focus in the component after re-rendering when module changed
          // eslint-disable-next-line react/no-array-index-key
          key={`requirement-${index}`}
          requirement={requirement}
          moduleItems={[requirement, ...availableModuleItems]}
          onDropRequirement={i => {
            internalLastAction.current = {action: 'delete', index: i}
            onDropRequirement(i)
          }}
          onUpdateRequirement={onUpdateRequirement}
          index={index}
          focusDropdown={focus?.type === 'dropdown' && focus?.index === index}
          focusDeleteButton={focus?.type === 'button' && focus?.index === index}
        />
      ))}
      {availableModuleItems.length > 0 && (
        <Button
          ref={addRequirementButton}
          onClick={() => {
            internalLastAction.current = {action: 'add', index: requirements.length}
            onAddRequirement({
              ...availableModuleItems[0],
              type: 'view',
            } as Requirement)
          }}
          renderIcon={<IconAddLine />}
        >
          {I18n.t('Requirement')}
        </Button>
      )}
    </FormFieldGroup>
  )
}
