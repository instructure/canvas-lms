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

import React, {useState, useRef, useEffect} from "react"
import {Flex} from '@instructure/ui-flex'
import {Menu} from '@instructure/ui-menu'
import {Button} from '@instructure/ui-buttons'
import {IconArrowOpenDownSolid,IconConfigureSolid} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import DifferentiationTagTrayManager from '@canvas/differentiation-tags/react/DifferentiationTagTray/DifferentiationTagTrayManager'
import {useDifferentiationTagCategoriesIndex} from '../hooks/useDifferentiationTagCategoriesIndex'
import DifferentiationTagModalManager from '@canvas/differentiation-tags/react/DifferentiationTagModalForm/DifferentiationTagModalManager'
import {useAddTagMembership} from '../hooks/useAddTagMembership'
import MessageBus from '@canvas/util/MessageBus'
import $ from 'jquery'

const I18n = createI18nScope('differentiation_tags')

export interface UserDifferentiationTagManagerProps {
  courseId: number
  users: number[]
}

type HandleMenuSelection = (
  e: React.SyntheticEvent<Element, Event>,
  selected: string | number | (string | number | undefined)[] | undefined
) => void

const TagAsMenu = (props: {courseId: number, handleMenuSelection: HandleMenuSelection}) => {
  const {courseId, handleMenuSelection} = props
  const {
    data: differentiationTagCategories,
    isLoading,
    error,
  } = useDifferentiationTagCategoriesIndex(
        courseId,
        {
          includeDifferentiationTags: true,
          enabled: true,
        }
      )
  const fallbackTitle = () => {
    if(isLoading)
      return I18n.t('Fetching Categories...')
    if(error)
      return I18n.t('Error Fetching Categories!')
    if(!isLoading && !error)
      return I18n.t('No Differentiation Tag Categories Yet')
  }
  const empty = [{ id: 1, name: fallbackTitle(), groups: [],}]

  return (
    <Menu
      placement="bottom center"
      onSelect={handleMenuSelection}
      trigger={
        <Button
          color="primary"
          data-testid="user-diff-tag-manager-tag-as-button"
        >
          {I18n.t('Tag As ')}
          <IconArrowOpenDownSolid/>
        </Button>
      }
      maxHeight='20rem'
    >
      {(differentiationTagCategories?.length ? differentiationTagCategories : empty).map(option =>
      option && option.groups && option.groups.length === 1 && option.name === option.groups[0].name ? ([
        <Menu.Item
            key={`tag-group-${option.groups[0].id}`}
            value={option.groups[0].id}
            themeOverride={{
              labelPadding: '0.75rem'
            }}
          >
              {option.groups[0].name}
        </Menu.Item>,
        <Menu.Separator/>
        ]) : ([
        <Menu.Group
          key={`tag-set-${option.id}`}
          label={option.name}
          allowMultiple={false}
        >
          {option.groups && option.groups.map(groupOption => (
            <Menu.Item
              key={`tag-group-${groupOption.id}`}
              value={groupOption.id}
              themeOverride={{
                labelPadding: '0.75rem'
              }}
            >
                {groupOption.name}
            </Menu.Item>
          ))}
        </Menu.Group>,
        <Menu.Separator/>
      ]))}
      <Menu.Separator/>
      <Menu.Item
        value={-1}
        themeOverride={{
          labelPadding: '0.75rem',
          fontWeight:	700
        }}
      >
        <IconConfigureSolid/> {I18n.t('New Tag')}
      </Menu.Item>
    </Menu>
  )
}
export default function UserDifferentiationTagManager(props: UserDifferentiationTagManagerProps) {
  const {courseId, users} = props
  const manageTagsRefButton = useRef<HTMLElement | null>(null)
  const [isOpen, setIsOpen] = useState(false)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const { mutate, isLoading: isAdding, isSuccess, isError, error: errorAdd, } = useAddTagMembership()
  const handleMenuSelection: HandleMenuSelection = (e, selected) => {
    if (users.length === 0 && selected !== -1) {
      $.flashError(I18n.t('Select one or more users first'))
      return
    }

    if (Array.isArray(selected)) {
      if (selected.length > 0 && selected[0]) {
        // Directly use the first element as groupId
        mutate({groupId: selected[0], userIds: users})
      }
      return
    }

    if (typeof selected === 'number') {
      if (selected === -1) {
        setIsModalOpen(true)
      } else if (selected > 0) {
        mutate({groupId: selected, userIds: users})
      }
    }
  }

  const onTrayClose = () => {
    setIsOpen(false)
    if(manageTagsRefButton.current)
      manageTagsRefButton.current.focus()
  }
  useEffect(() => {
    if(isSuccess) {
      MessageBus.trigger('reloadUsersTable', {})
      $.flashMessage(I18n.t('Tag added successfully'))
    }
    if(isError) {
      $.flashError(I18n.t('Error: %{error}', {error: errorAdd.message}))
    }
  }, [isSuccess, isError])
  return (
    <>
      <Flex as="div" alignItems="center" justifyItems="start" gap="none" direction="row" width="100%" >
        <Flex.Item margin="xx-small">
          <Text data-testid="user-diff-tag-manager-user-count">{I18n.t('%{userCount} Selected', {userCount: users.length})}</Text>
        </Flex.Item>
        <Flex.Item margin="xx-small">
          <TagAsMenu
            courseId={courseId}
            handleMenuSelection={handleMenuSelection}
          />
        </Flex.Item>
        <Flex.Item margin="xx-small">
          <Button
            elementRef={ ref => manageTagsRefButton.current = ref as HTMLButtonElement}
            onClick={() =>{
                if (ENV.current_context?.type === 'Course') {
                    setIsOpen(true)
                }
            }}
            data-testid="user-diff-tag-manager-manage-tags-button"
          >
            {I18n.t('Manage Tags')}
          </Button>
        </Flex.Item>
      </Flex>
      <DifferentiationTagTrayManager
        isOpen={isOpen}
        onClose={onTrayClose}
        courseID={courseId}
      />
      <DifferentiationTagModalManager
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        mode="create"
        differentiationTagCategoryId={undefined}
      />
    </>
  )
}