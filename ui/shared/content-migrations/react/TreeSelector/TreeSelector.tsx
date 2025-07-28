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
import React, {type ComponentClass, Fragment, memo, useEffect, useReducer, useState} from 'react'
import {Flex, FlexItem} from '@instructure/ui-flex'
import {Checkbox} from '@instructure/ui-checkbox'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {ToggleGroup} from '@instructure/ui-toggle-details'
import {useScope as useI18nScope} from '@canvas/i18n'
import {
  IconAnnouncementLine,
  IconAssignmentLine,
  IconCalendarDaysLine,
  IconCollectionLine,
  IconDiscussionLine,
  IconDocumentLine,
  IconFolderLine,
  IconGroupLine,
  IconHourGlassLine,
  IconLtiLine,
  IconModuleLine,
  IconNoteLine,
  IconOutcomesLine,
  IconQuizLine,
  IconRubricLine,
  IconSettingsLine,
  IconSyllabusLine,
} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'

export type CheckboxState = 'checked' | 'unchecked' | 'indeterminate'

export type SwitchState = 'on' | 'off' | 'disabled'

export type CheckboxTreeNode = {
  id: string
  label: string
  type: ItemType
  linkedId?: string
  parentId?: string
  childrenIds: string[]
  checkboxState: CheckboxState
  migrationId?: string
  importAsOneModuleItemState?: SwitchState
}

export type TreeSelectorProps = {
  checkboxTreeNodes: Record<string, CheckboxTreeNode>
  onChange: (modifiedItems: Record<string, CheckboxTreeNode>) => void
}

type DispatcherType = CheckboxState | 'importAsOneModuleItem'

type ItemProps = {
  currentItem: CheckboxTreeNode
  dispatch: (action: {type: DispatcherType; payload: string}) => void
  expanded?: boolean
  checkboxTreeNodes?: Record<string, CheckboxTreeNode>
}

export type ItemType =
  | 'course_settings'
  | 'syllabus_body'
  | 'course_paces'
  | 'context_modules'
  | 'assignments'
  | 'quizzes'
  | 'assessment_question_banks'
  | 'discussion_topics'
  | 'wiki_pages'
  | 'context_external_tools'
  | 'tool_profiles'
  | 'announcements'
  | 'calendar_events'
  | 'rubrics'
  | 'groups'
  | 'learning_outcomes'
  | 'learning_outcome_groups'
  | 'attachments'
  | 'assignment_groups'
  | 'folders'
  | 'blueprint_settings'

const ICONS: Record<ItemType, ComponentClass<any>> = {
  course_settings: IconSettingsLine,
  syllabus_body: IconSyllabusLine,
  course_paces: IconHourGlassLine,
  context_modules: IconModuleLine,
  assignments: IconAssignmentLine,
  quizzes: IconQuizLine,
  assessment_question_banks: IconCollectionLine,
  discussion_topics: IconDiscussionLine,
  wiki_pages: IconNoteLine,
  context_external_tools: IconLtiLine,
  tool_profiles: IconLtiLine,
  announcements: IconAnnouncementLine,
  calendar_events: IconCalendarDaysLine,
  rubrics: IconRubricLine,
  groups: IconGroupLine,
  learning_outcomes: IconOutcomesLine,
  learning_outcome_groups: IconFolderLine,
  attachments: IconDocumentLine,
  assignment_groups: IconFolderLine,
  folders: IconFolderLine,
  blueprint_settings: IconSettingsLine,
}

const updateChildrenToNextState = (
  item: CheckboxTreeNode,
  newState: Record<string, CheckboxTreeNode>,
  updaterFunction: (treeNodes: Record<string, CheckboxTreeNode>, childId: string) => void,
) => {
  const updateChild = (currentItem: CheckboxTreeNode) => {
    currentItem.childrenIds.forEach(childId => {
      const childItem = newState[childId]
      updaterFunction(newState, childId)
      if (childItem) updateChild(childItem)
    })
  }

  updateChild(item)
}

const updateParentsWithoutKnowAboutChildren = (
  item: CheckboxTreeNode,
  newState: Record<string, CheckboxTreeNode>,
) => {
  let itemForParentTraversal = item

  while (itemForParentTraversal && itemForParentTraversal.parentId) {
    const parent = newState[itemForParentTraversal.parentId]
    const children = parent.childrenIds.map(childId => newState[childId])
    const checkedChildren = children.filter(child => child.checkboxState === 'checked')
    const indeterminateChildren = children.filter(child => child.checkboxState === 'indeterminate')

    if (checkedChildren.length === children.length) {
      newState[itemForParentTraversal.parentId] = {...parent, checkboxState: 'checked'}
    } else if (checkedChildren.length > 0 || indeterminateChildren.length > 0) {
      newState[itemForParentTraversal.parentId] = {...parent, checkboxState: 'indeterminate'}
    } else {
      newState[itemForParentTraversal.parentId] = {...parent, checkboxState: 'unchecked'}
    }

    itemForParentTraversal = parent
  }
}

const uncheckAllChildrenAction = (
  state: Record<string, CheckboxTreeNode>,
  id: string,
): Record<string, CheckboxTreeNode> => {
  const newState = {...state}
  const item = newState[id]

  if (item) {
    const nextCheckState = 'unchecked'
    newState[item.id] = {...item, checkboxState: nextCheckState}

    updateChildrenToNextState(item, newState, (treeNodes, childId) => {
      treeNodes[childId] = {... treeNodes[childId], checkboxState: nextCheckState}
    })
    updateParentsWithoutKnowAboutChildren(item, newState)
  }

  return newState
}

const toggleCheckBoxByIdAction = (
  state: Record<string, CheckboxTreeNode>,
  id: string,
): Record<string, CheckboxTreeNode> => {
  const newState = {...state}
  const item = newState[id]

  if (item) {
    const nextCheckState = item.checkboxState === 'checked' ? 'unchecked' : 'checked'
    newState[item.id] = {...item, checkboxState: nextCheckState}

    updateParentsWithoutKnowAboutChildren(item, newState)
  }

  return newState
}

const toggleImportAsOneModuleItem = (
  state: Record<string, CheckboxTreeNode>,
  id: string,
): Record<string, CheckboxTreeNode> => {
  const newState = {...state}
  const item = newState[id]

  if (item) {
    const nextImportAsOneModuleItemState = item.importAsOneModuleItemState === 'on' ? 'off' : 'on'
    newState[item.id] = {...item, importAsOneModuleItemState: nextImportAsOneModuleItemState}
    if (nextImportAsOneModuleItemState === 'off') {
      updateChildrenToNextState(item, newState, (treeNodes, childId) => {
        treeNodes[childId] = {...treeNodes[childId], importAsOneModuleItemState: 'disabled'}
      })
    }
    if (nextImportAsOneModuleItemState === 'on') {
      updateChildrenToNextState(item, newState, (treeNodes, childId) => {
        treeNodes[childId] = {...treeNodes[childId], importAsOneModuleItemState: 'off'}
      })
    }
  }

  return newState
}

const reducer = (
  state: Record<string, CheckboxTreeNode>,
  action: {type: DispatcherType; payload: string},
) => {
  switch (action.type) {
    case 'unchecked':
    case 'checked':
      return toggleCheckBoxByIdAction(state, action.payload)
    case 'indeterminate':
      return uncheckAllChildrenAction(state, action.payload)
    case 'importAsOneModuleItem':
      return toggleImportAsOneModuleItem(state, action.payload)
    default:
      return state
  }
}

const filterChildrenByParentId = (
  items: Record<string, CheckboxTreeNode>,
  childrenIds: string[],
) => {
  return (
    Object.values(items)
      .filter(item => childrenIds.includes(item.id))
      .map(item => item) || []
  )
}

const filterParents = (items: Record<string, CheckboxTreeNode>) => {
  return (
    Object.values(items)
      .filter(item => item.parentId === undefined)
      .map(item => item) || []
  )
}

const isParentItem = (item: CheckboxTreeNode) => {
  return item.childrenIds.length > 0
}

const areEqualChild = (prevProps: ItemProps, nextProps: ItemProps) => {
  return (
    prevProps.currentItem.checkboxState === nextProps.currentItem.checkboxState &&
    prevProps.currentItem.importAsOneModuleItemState === nextProps.currentItem.importAsOneModuleItemState &&
    prevProps.dispatch === nextProps.dispatch
  )
}

const areEqualParent = (prevProps: ItemProps, nextProps: ItemProps) => {
  const prevNodes = prevProps.checkboxTreeNodes || {}
  const nextNodes = nextProps.checkboxTreeNodes || {}

  const hasChildStateChangedRecursive = (
    currentItem: CheckboxTreeNode,
    prevNodesParam: Record<string, CheckboxTreeNode>,
    nextNodesParam: Record<string, CheckboxTreeNode>,
  ): boolean => {
    if (prevNodesParam[currentItem.id].importAsOneModuleItemState !== nextNodesParam[currentItem.id].importAsOneModuleItemState) {
      return true
    }

    return currentItem.childrenIds.some(childId => {
      const child = prevNodesParam[childId]
      if (child.childrenIds.length > 0) {
        return hasChildStateChangedRecursive(child, prevNodesParam, nextNodesParam)
      }

      return child.checkboxState !== nextNodesParam[childId].checkboxState ||
        prevNodesParam[childId].importAsOneModuleItemState !== nextNodesParam[childId].importAsOneModuleItemState
    })
  }

  const hasChildStateChanged = hasChildStateChangedRecursive(
    prevProps.currentItem,
    prevNodes,
    nextNodes,
  )

  return (
    !hasChildStateChanged &&
    prevProps.currentItem.checkboxState === nextProps.currentItem.checkboxState &&
    prevProps.currentItem.importAsOneModuleItemState === nextProps.currentItem.importAsOneModuleItemState &&
    prevProps.expanded === nextProps.expanded &&
    prevProps.dispatch === nextProps.dispatch
  )
}

const SubModuleSwitch = ({
  checkboxState,
  dispatch,
  currentItem,
} : {
  checkboxState: CheckboxState
  dispatch: (action: {type: DispatcherType; payload: string}) => void
  currentItem: CheckboxTreeNode
}) => {
  const I18n = useI18nScope('collapsable_list')
  const {importAsOneModuleItemState} = currentItem

  const handleCheckboxChange = () => {
    dispatch({type: 'importAsOneModuleItem', payload: currentItem.id})
  }

  const checkboxLabel = (disabled: boolean) => (
    <>
      <Text>{I18n.t('Import as a standalone module')}</Text>
      <br/>
      {disabled ?
        <Text color="secondary">{I18n.t('Selection is disabled, as the parent is not selected as a standalone module import item.')}</Text> :
        <Text color="secondary">{I18n.t('If not selected, this item will be imported as one module item.')}</Text>
      }
    </>
  )

  const switchDisabled = importAsOneModuleItemState === 'disabled'
  const switchOn = importAsOneModuleItemState === 'on'
  const checkBoxChecked = checkboxState === 'checked'

  if (checkBoxChecked && importAsOneModuleItemState !== undefined) {
    return (
      <View
        margin="xx-small 0 xx-small x-large"
        as="div"
      >
        <Flex direction="row" wrap="wrap">
          <Checkbox
            label={checkboxLabel(switchDisabled)}
            value="small"
            variant="toggle"
            size="small"
            data-testid={`switch-${currentItem.id}`}
            disabled={switchDisabled}
            checked={switchOn}
            onChange={handleCheckboxChange}
          />
        </Flex>
      </View>
    )
  }

  return <></>
}

const Child = memo(({currentItem, dispatch}: ItemProps) => {
  const {id, label, type, checkboxState, linkedId} = currentItem

  const ParentIcon = ICONS[type] || ICONS.assignment_groups

  const handleCheckboxChange = () => {
    dispatch({type: checkboxState, payload: id})
    if (linkedId) {
      dispatch({type: checkboxState, payload: linkedId})
    }
  }

  return (
    <Flex direction="column">
      <FlexItem>
        <SubModuleSwitch
          checkboxState={checkboxState}
          dispatch={dispatch}
          currentItem={currentItem}
        />
      </FlexItem>
      <FlexItem>
        <Flex margin="0 0 0 x-large" padding="small 0 small xxx-small">
          <FlexItem margin="0 x-small 0 0">
            <Checkbox
              checked={checkboxState === 'checked'}
              onChange={handleCheckboxChange}
              label={<ScreenReaderContent>{label}</ScreenReaderContent>}
              data-testid={`checkbox-${id}`}
            />
          </FlexItem>
          {ParentIcon && (
            <FlexItem margin="0 small 0 0">
              <ParentIcon size="x-small" />
            </FlexItem>
          )}
          <FlexItem shouldShrink={true}>
            <Text aria-hidden="true">{label}</Text>
          </FlexItem>
        </Flex>
      </FlexItem>
    </Flex>
  )
}, areEqualChild)

const Parent = memo(
  ({currentItem, dispatch, checkboxTreeNodes = {}, expanded = false}: ItemProps) => {
    const [expandedState, setExpandedState] = useState<boolean>(expanded)
    const I18n = useI18nScope('collapsable_list')
    const {id, label, type, childrenIds, checkboxState} = currentItem

    const ParentIcon = ICONS[type] || ICONS.assignment_groups

    const childItems = filterChildrenByParentId(checkboxTreeNodes, childrenIds)

    const handleCheckboxChange = () => {
      const updateOnlyLastChildItems = (items: CheckboxTreeNode[]) => {
        items.forEach(item => {
          if (isParentItem(item)) {
            const nestedChildItems = item.childrenIds.map(childId => checkboxTreeNodes[childId])
            updateOnlyLastChildItems(nestedChildItems)
          } else {
            dispatch({type: checkboxState, payload: item.id})
            if (item.linkedId) {
              dispatch({type: checkboxState, payload: item.linkedId})
            }
          }
        })
      }

      // We not call toggle on current Parent element only on last children in the tree,
      // because the children state update will determine the parents state as bubbling up the state
      updateOnlyLastChildItems(childItems)
    }
    const handleExpand = () => {
      setExpandedState(!expandedState)
    }

    return (
      <Flex margin="xxx-small 0 0 0" width="100%" direction="column">
        <FlexItem shouldShrink={true}>
          <SubModuleSwitch
            checkboxState={checkboxState}
            dispatch={dispatch}
            currentItem={currentItem}
          />
          <ToggleGroup
            data-testid={`toggle-${id}`}
            toggleLabel={I18n.t('%{label}, View All', {label})}
            expanded={expandedState}
            onToggle={handleExpand}
            border={false}
            summary={
              <Flex>
                <FlexItem padding="x-small xx-small" shouldShrink={true}>
                  <Checkbox
                    checked={checkboxState === 'checked'}
                    indeterminate={checkboxState === 'indeterminate'}
                    onChange={handleCheckboxChange}
                    label={<ScreenReaderContent>{label}</ScreenReaderContent>}
                    data-testid={`checkbox-${id}`}
                  />
                </FlexItem>
                {ParentIcon && (
                  <FlexItem shouldShrink={true}>
                    <ParentIcon size="x-small" />
                  </FlexItem>
                )}
                <FlexItem padding="0 small" shouldShrink={true}>
                  <Text aria-hidden="true">{label}</Text>
                </FlexItem>
              </Flex>
            }
          >
            {childItems.map(childItem => {
              return isParentItem(childItem) ? (
                <Flex key={childItem.id} margin="0 0 0 large">
                  <Parent
                    currentItem={childItem}
                    checkboxTreeNodes={checkboxTreeNodes}
                    dispatch={dispatch}
                    expanded={false}
                  />
                </Flex>
              ) : (
                <Flex key={childItem.id} margin="0 0 0 large">
                  <Child key={childItem.id} currentItem={childItem} dispatch={dispatch} />
                </Flex>
              )
            })}
          </ToggleGroup>
        </FlexItem>
      </Flex>
    )
  },
  areEqualParent,
)

export const TreeSelector = ({
  checkboxTreeNodes: initCheckboxTreeNodes,
  onChange,
}: TreeSelectorProps) => {
  const [checkboxTreeNodes, checkDispatch] = useReducer(reducer, initCheckboxTreeNodes)

  useEffect(() => {
    onChange(checkboxTreeNodes)
  }, [checkboxTreeNodes, onChange])

  const rootItems = filterParents(checkboxTreeNodes)

  return (
    <>
      {rootItems.map(rootItem => {
        return (
          <Fragment key={rootItem.id}>
            {isParentItem(rootItem) ? (
              <Parent
                currentItem={rootItem}
                checkboxTreeNodes={checkboxTreeNodes}
                dispatch={checkDispatch}
                expanded={false}
              />
            ) : (
              <Flex padding="xx-small 0 0 0" width="100%" direction="column">
                <FlexItem shouldShrink={true}>
                  <Child currentItem={rootItem} dispatch={checkDispatch} />
                </FlexItem>
              </Flex>
            )}
          </Fragment>
        )
      })}
    </>
  )
}
