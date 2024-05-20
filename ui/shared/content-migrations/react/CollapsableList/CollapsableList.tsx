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

import React, {Fragment, type ComponentClass, useState, useEffect, useRef, useCallback} from 'react'
import {Flex} from '@instructure/ui-flex'
// @ts-ignore
import {Checkbox} from '@instructure/ui-checkbox'
import {Text} from '@instructure/ui-text'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {useScope as useI18nScope} from '@canvas/i18n'

const {Item: FlexItem} = Flex as any
const I18n = useI18nScope('collapsable_list')

type SingleItemCheckboxProps = {
  id: string
  label: string
  icon?: ComponentClass<{size: string}>
  isRoot?: boolean
  state?: CheckboxState
  onNotifyChangeToParent: (newState: CheckboxState, updatedCheckedIds: string[]) => void
}

type ParentItemCheckboxProps = SingleItemCheckboxProps & {
  items: Item[]
}

type CheckboxState = 'checked' | 'unchecked' | 'indeterminate'
type ChildrenStates = {[key: string]: CheckboxState}
type ChildrenSelectedIds = {[key: string]: string[]}

export type Item = {
  id: string
  label: string
  icon?: ComponentClass<{size: string}>
  children?: Item[]
}

export type CollapsableListProps = {
  items: Item[]
  onChange: (selectedIds: string[]) => void
}

const generateParentState = (childrenValues: CheckboxState[]): CheckboxState => {
  const hasIndeterminateChild = childrenValues.some(childValue => childValue === 'indeterminate')
  if (hasIndeterminateChild) return 'indeterminate'

  const checkedChildren = childrenValues.filter(childValue => childValue === 'checked')
  if (checkedChildren.length === childrenValues.length) return 'checked'
  if (checkedChildren.length > 0 && checkedChildren.length < childrenValues.length)
    return 'indeterminate'
  return 'unchecked'
}

const generateCheckedIds = (
  states: {[key: string]: CheckboxState},
  id?: string,
  newState?: CheckboxState
): string[] => {
  let selectedIds: string[]
  if (id && newState === 'checked') {
    selectedIds = [id]
  } else if (id && newState === 'unchecked') {
    selectedIds = []
  } else {
    selectedIds = Object.keys(states).filter(childKey => states[childKey] === 'checked')
  }
  return selectedIds
}

const generateUpdatedCheckedIds = (
  childrenStates: ChildrenStates,
  childrenSelectedIds: ChildrenSelectedIds,
  id?: string,
  newParentState?: CheckboxState
) => {
  const checkedIds = generateCheckedIds(childrenStates, id, newParentState)
  if (id && newParentState === 'checked') {
    return checkedIds
  }

  const joinedChildrenCheckedIds = Object.values(childrenSelectedIds).reduce(
    (result, ids) => [...result, ...ids],
    []
  )
  return Array.from(new Set([...joinedChildrenCheckedIds, ...checkedIds]))
}

const ParentItemCheckbox = ({
  id,
  label,
  icon,
  items,
  onNotifyChangeToParent,
  state = 'unchecked',
  isRoot = false,
}: ParentItemCheckboxProps) => {
  const [innerState, setInnerState] = useState(state)
  const [expanded, setExpanded] = useState(false)
  const [childrenStates, setChildrenStates] = useState<ChildrenStates>(() => {
    const initialValue: {[key: string]: CheckboxState} = {}
    items.forEach(item => (initialValue[item.id] = state))
    return initialValue
  })
  const childrenSelectedIdsRef = useRef<ChildrenSelectedIds>({})

  useEffect(() => {
    items.forEach(
      item => (childrenSelectedIdsRef.current[item.id] = state === 'checked' ? [item.id] : [])
    )
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const handleCheck = useCallback(
    (checked: boolean) => {
      const newParentState = checked ? 'checked' : 'unchecked'
      Object.keys(childrenStates).forEach(k => (childrenStates[k] = newParentState))
      const checkedIds = generateCheckedIds(childrenStates, id, newParentState)

      setInnerState(newParentState)
      setChildrenStates(childrenStates)
      onNotifyChangeToParent(newParentState, checkedIds)
    },
    [id, childrenStates, onNotifyChangeToParent]
  )

  const handleNotifyChangeToParent = useCallback(
    (itemId: string) => (newChildState: CheckboxState, childSelectedIds: string[]) => {
      childrenStates[itemId] = newChildState
      childrenSelectedIdsRef.current[itemId] = childSelectedIds

      const newState = generateParentState(Object.values(childrenStates))
      const updatedCheckedIds = generateUpdatedCheckedIds(
        childrenStates,
        childrenSelectedIdsRef.current,
        id,
        newState
      )

      setInnerState(newState)
      setChildrenStates(childrenStates)
      onNotifyChangeToParent(newState, updatedCheckedIds)
    },
    [id, childrenStates, onNotifyChangeToParent]
  )

  const ParentIcon = icon

  return (
    <Flex
      margin={isRoot ? '0' : 'xxx-small 0 0 medium'}
      padding={isRoot ? 'x-small 0 x-small 0' : 'x-small 0 0 0'}
    >
      <FlexItem shouldShrink={true}>
        <ToggleDetails
          data-testid={`toggle-${id}`}
          aria-label={I18n.t('%{label}, Navigate inside to interact with the checkbox', {label})}
          expanded={expanded}
          onToggle={() => setExpanded(!expanded)}
          summary={
            <Flex>
              <FlexItem padding={isRoot ? 'x-small' : 'x-small'} shouldShrink={true}>
                <Checkbox
                  checked={innerState === 'checked'}
                  indeterminate={innerState === 'indeterminate'}
                  onChange={(e: any) => handleCheck(e.target.checked)}
                  label={<ScreenReaderContent>{label}</ScreenReaderContent>}
                  data-testid={`checkbox-${id}`}
                />
              </FlexItem>
              {ParentIcon && (
                <FlexItem shouldShrink={true}>
                  <ParentIcon size="small" />
                </FlexItem>
              )}
              <FlexItem padding="0 small" shouldShrink={true}>
                <Text aria-hidden="true">{label}</Text>
              </FlexItem>
            </Flex>
          }
        >
          {items.map(item =>
            item.children ? (
              <ParentItemCheckbox
                key={item.id}
                id={item.id}
                label={item.label}
                icon={item.icon}
                items={item.children}
                state={childrenStates[item.id]}
                onNotifyChangeToParent={handleNotifyChangeToParent(item.id)}
              />
            ) : (
              <SingleItemCheckbox
                key={item.id}
                id={item.id}
                label={item.label}
                icon={item.icon}
                state={childrenStates[item.id]}
                onNotifyChangeToParent={handleNotifyChangeToParent(item.id)}
              />
            )
          )}
        </ToggleDetails>
      </FlexItem>
    </Flex>
  )
}

const SingleItemCheckbox = ({
  id,
  label,
  icon,
  onNotifyChangeToParent,
  state = 'unchecked',
  isRoot = false,
}: SingleItemCheckboxProps) => {
  const [innerState, seInnerState] = useState<CheckboxState>(state)

  const handleCheck = useCallback(
    (checked: boolean) => {
      const newState = checked ? 'checked' : 'unchecked'
      seInnerState(newState)
      onNotifyChangeToParent(newState, newState === 'checked' ? [id] : [])
    },
    [id, onNotifyChangeToParent]
  )

  useEffect(() => {
    innerState !== state && seInnerState(state)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [state])

  const ParentIcon = icon

  return (
    <Flex
      margin={isRoot ? '0 0 0 medium' : '0 0 0 x-large'}
      padding={isRoot ? 'x-small xxx-small' : 'x-small 0'}
    >
      {/* Needed to do that to properly indent the item */}
      {!isRoot && <FlexItem margin="0 xxx-small 0 0" />}
      <FlexItem margin="0 x-small 0 0" shouldShrink={true}>
        <Checkbox
          checked={innerState === 'checked'}
          onChange={(e: any) => handleCheck(e.target.checked)}
          label={<ScreenReaderContent>{label}</ScreenReaderContent>}
          data-testid={`checkbox-${id}`}
        />
      </FlexItem>
      {ParentIcon && (
        <FlexItem margin="0 small 0 0" shouldShrink={true}>
          <ParentIcon size="small" />
        </FlexItem>
      )}
      <FlexItem shouldShrink={true}>
        <Text aria-hidden="true">{label}</Text>
      </FlexItem>
    </Flex>
  )
}

export const CollapsableList = ({items, onChange}: CollapsableListProps) => {
  const [childrenStates, setChildrenStates] = useState<ChildrenStates>(() => {
    const initialValue: ChildrenStates = {}
    items.forEach(item => (initialValue[item.id] = 'unchecked'))
    return initialValue
  })
  const childrenSelectedIdsRef = useRef<ChildrenSelectedIds>({})

  useEffect(() => {
    items.forEach(item => (childrenSelectedIdsRef.current[item.id] = []))
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const handleNotifyChangeToParent = useCallback(
    (itemId: string) => (newChildState: CheckboxState, childSelectedIds: string[]) => {
      childrenStates[itemId] = newChildState
      childrenSelectedIdsRef.current[itemId] = childSelectedIds

      const checkedIds = generateUpdatedCheckedIds(childrenStates, childrenSelectedIdsRef.current)

      setChildrenStates(childrenStates)
      onChange(checkedIds)
    },
    [childrenStates, onChange]
  )

  return (
    <>
      {items.map((item, index) => {
        return (
          <Fragment key={item.id}>
            {item.children ? (
              <ParentItemCheckbox
                id={item.id}
                label={item.label}
                icon={item.icon}
                items={item.children}
                state={childrenStates[item.id]}
                onNotifyChangeToParent={handleNotifyChangeToParent(item.id)}
              />
            ) : (
              <SingleItemCheckbox
                id={item.id}
                label={item.label}
                icon={item.icon}
                state={childrenStates[item.id]}
                onNotifyChangeToParent={handleNotifyChangeToParent(item.id)}
              />
            )}
            {index + 1 < items.length && <hr />}
          </Fragment>
        )
      })}
    </>
  )
}
