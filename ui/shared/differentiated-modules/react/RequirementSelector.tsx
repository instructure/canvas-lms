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

import React, {useEffect, useMemo, useRef} from 'react'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {NumberInput} from '@instructure/ui-number-input'
import {IconButton} from '@instructure/ui-buttons'
import {IconTrashLine} from '@instructure/ui-icons'
import CanvasSelect from '@canvas/instui-bindings/react/Select'
import type {Requirement, ModuleItem} from './types'
import {requirementTypesForResource} from '../utils/miscHelpers'
import {groupBy} from 'lodash'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('differentiated_modules')

const resourceLabelMap: Record<ModuleItem['resource'], string> = {
  assignment: I18n.t('Assignments'),
  quiz: I18n.t('Quizzes'),
  file: I18n.t('Files'),
  page: I18n.t('Pages'),
  discussion: I18n.t('Discussions'),
  externalUrl: I18n.t('External URLs'),
  externalTool: I18n.t('External Tools'),
}

const requirementTypeLabelMap: Record<Requirement['type'], string> = {
  view: I18n.t('View the item'),
  mark: I18n.t('Mark as done'),
  submit: I18n.t('Submit the assignment'),
  score: I18n.t('Score at least'),
  contribute: I18n.t('Contribute to the page'),
}

export interface RequirementSelectorProps {
  requirement: Requirement
  moduleItems: ModuleItem[]
  onDropRequirement: (index: number) => void
  onUpdateRequirement: (module: Requirement, index: number) => void
  index: number
  focusDropdown?: boolean
  focusDeleteButton?: boolean
}

export default function RequirementSelector({
  requirement,
  moduleItems,
  onDropRequirement,
  onUpdateRequirement,
  index,
  focusDropdown = false,
  focusDeleteButton = false,
}: RequirementSelectorProps) {
  const removeButton = useRef<Element | null>(null)
  const dropdown = useRef<HTMLInputElement | null>(null)
  const requirementTypeOptions = useMemo(() => {
    const requirementTypes = requirementTypesForResource(requirement.resource)
    return requirementTypes.map(type => {
      return {type, label: requirementTypeLabelMap[type]}
    })
  }, [requirement.resource])

  const options = useMemo(() => groupBy(moduleItems, 'resource'), [moduleItems])

  useEffect(() => {
    // @ts-expect-error
    focusDeleteButton && removeButton.current?.focus()
  }, [focusDeleteButton, removeButton])

  useEffect(() => {
    focusDropdown && dropdown.current?.focus()
  }, [focusDropdown, dropdown])

  return (
    <View data-testid="module-requirement-card" as="div" borderRadius="medium" borderWidth="small">
      <View as="div" padding="medium">
        <Flex direction="row">
          <Flex.Item shouldGrow={true}>
            <Text>{I18n.t('Content')}</Text>
          </Flex.Item>
          <Flex.Item padding="0 0 small 0">
            <IconButton
              elementRef={el => (removeButton.current = el)}
              renderIcon={<IconTrashLine color="error" />}
              onClick={() => onDropRequirement(index)}
              screenReaderLabel={I18n.t('Remove %{name} Content Requirement', {
                name: requirement.name,
              })}
              withBackground={false}
              withBorder={false}
            />
          </Flex.Item>
        </Flex>
        <View as="div" padding="0 0 small 0">
          <CanvasSelect
            id={`requirement-item-${index}`}
            // @ts-expect-error
            inputRef={el => (dropdown.current = el)}
            value={requirement.name}
            label={<ScreenReaderContent>{I18n.t('Select Module Item')}</ScreenReaderContent>}
            onChange={(_event, value) => {
              const moduleItem = moduleItems.find(item => item.name === value)!
              onUpdateRequirement({...moduleItem, type: 'view'} as Requirement, index)
            }}
          >
            {/* @ts-expect-error */}
            {Object.keys(options).map((resource: ModuleItem['resource']) => {
              return (
                <CanvasSelect.Group key={resource} label={resourceLabelMap[resource]}>
                  {options[resource].map((moduleItem: ModuleItem) => (
                    <CanvasSelect.Option
                      id={moduleItem.id}
                      key={moduleItem.id}
                      value={moduleItem.name}
                    >
                      {moduleItem.name}
                    </CanvasSelect.Option>
                  ))}
                </CanvasSelect.Group>
              )
            })}
          </CanvasSelect>
        </View>
        <CanvasSelect
          id={`requirement-type-${index}`}
          value={requirement.type}
          label={<ScreenReaderContent>{I18n.t('Select Requirement Type')}</ScreenReaderContent>}
          onChange={(_event, value) => {
            onUpdateRequirement({...requirement, type: value} as Requirement, index)
          }}
        >
          {requirementTypeOptions.map(({type, label}) => {
            return (
              <CanvasSelect.Option id={type} key={type} value={type}>
                {label}
              </CanvasSelect.Option>
            )
          })}
        </CanvasSelect>
        {requirement.type === 'score' && (
          <Flex padding="small 0">
            <Flex.Item shouldShrink={true}>
              <NumberInput
                value={requirement.minimumScore}
                width="4rem"
                showArrows={false}
                renderLabel={<ScreenReaderContent>{I18n.t('Minimum Score')}</ScreenReaderContent>}
                onChange={event => {
                  onUpdateRequirement(
                    {...requirement, minimumScore: event.target.value} as Requirement,
                    index
                  )
                }}
              />
            </Flex.Item>
            <Flex.Item shouldGrow={true} padding="0 0 0 small">
              {requirement.pointsPossible && (
                <View as="div">
                  <ScreenReaderContent>{I18n.t('Points Possible')}</ScreenReaderContent>
                  <Text data-testid="points-possible-value">{`/ ${requirement.pointsPossible}`}</Text>
                </View>
              )}
            </Flex.Item>
          </Flex>
        )}
      </View>
    </View>
  )
}
