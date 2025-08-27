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

import React, {useState, useRef, useEffect, useContext} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Menu} from '@instructure/ui-menu'
import {Button} from '@instructure/ui-buttons'
import {IconArrowOpenDownSolid, IconConfigureSolid} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import DifferentiationTagTrayManager from '@canvas/differentiation-tags/react/DifferentiationTagTray/DifferentiationTagTrayManager'
import {useDifferentiationTagCategoriesIndex} from '../hooks/useDifferentiationTagCategoriesIndex'
import DifferentiationTagModalManager from '@canvas/differentiation-tags/react/DifferentiationTagModalForm/DifferentiationTagModalManager'
import {useAddTagMembership} from '../hooks/useAddTagMembership'
import MessageBus from '@canvas/util/MessageBus'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {bulkDeleteGroupMemberships, bulkFetchUserTags, getCommonTagIds} from '../util/diffTagUtils'

const I18n = createI18nScope('differentiation_tags')

export interface UserDifferentiationTagManagerProps {
  courseId: number
  users: number[]
  allInCourse?: boolean
  userExceptions?: number[]
}

type HandleMenuSelection = (
  e: React.SyntheticEvent<Element, Event>,
  selected: string | number | (string | number | undefined)[] | undefined,
) => void

function getTagMenuLabel(groupId: number, groupName: string, commonTagGroupIds: Set<number>) {
  return commonTagGroupIds.has(groupId) ? `${I18n.t('Untag')} ${groupName}` : groupName
}

const TagAsMenu = (props: {
  courseId: number
  handleMenuSelection: HandleMenuSelection
  userTags: Record<number, number[]>
  users: number[]
}) => {
  const {courseId, handleMenuSelection, userTags, users} = props
  const {
    data: differentiationTagCategories,
    isLoading,
    error,
  } = useDifferentiationTagCategoriesIndex(courseId, {
    includeDifferentiationTags: true,
    enabled: true,
  })
  const fallbackTitle = () => {
    if (isLoading) return I18n.t('Fetching Categories...')
    if (error) return I18n.t('Error Fetching Categories!')
    if (!isLoading && !error) return I18n.t('No Differentiation Tag Categories Yet')
  }
  const empty = [{id: 1, name: fallbackTitle(), groups: []}]

  const commonTagGroupIds = getCommonTagIds(users, userTags)

  return (
    <Menu
      placement="bottom center"
      onSelect={handleMenuSelection}
      trigger={
        <Button color="primary" data-testid="user-diff-tag-manager-tag-as-button">
          {I18n.t('Tag As ')}
          <IconArrowOpenDownSolid />
        </Button>
      }
      maxHeight="20rem"
    >
      {(differentiationTagCategories?.length ? differentiationTagCategories : empty).map(option =>
        option &&
        option.groups &&
        option.groups.length === 1 &&
        option.name === option.groups[0].name
          ? [
              <Menu.Item
                key={`tag-group-${option.groups[0].id}`}
                value={option.groups[0].id}
                data-testid={`tag-group-${option.groups[0].name}`}
                themeOverride={{
                  labelPadding: '0.75rem',
                }}
              >
                {getTagMenuLabel(option.groups[0].id, option.groups[0].name, commonTagGroupIds)}
              </Menu.Item>,
              <Menu.Separator key={`tag-group-separator-${option.groups[0].id}`} />,
            ]
          : [
              <Menu.Group
                key={`tag-set-${option.id}`}
                label={option.name}
                data-testid={`tag-set-${option.name}`}
                allowMultiple={false}
              >
                {option.groups &&
                  option.groups.map(groupOption => (
                    <Menu.Item
                      key={`tag-group-${groupOption.id}`}
                      value={groupOption.id}
                      data-testid={`tag-group-${groupOption.name}`}
                      themeOverride={{
                        labelPadding: '0.75rem',
                      }}
                    >
                      {getTagMenuLabel(groupOption.id, groupOption.name, commonTagGroupIds)}
                    </Menu.Item>
                  ))}
              </Menu.Group>,
              <Menu.Separator key={`tag-group-separator-${option.id}`} />,
            ],
      )}
      <Menu.Separator />
      <Menu.Item
        value={-1}
        themeOverride={{
          labelPadding: '0.75rem',
          fontWeight: 700,
        }}
      >
        <IconConfigureSolid /> {I18n.t('New Tag')}
      </Menu.Item>
    </Menu>
  )
}

export default function UserDifferentiationTagManager(props: UserDifferentiationTagManagerProps) {
  const {courseId, users, allInCourse, userExceptions} = props
  const manageTagsRefButton = useRef<HTMLElement | null>(null)
  const [isOpen, setIsOpen] = useState(false)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const {mutate, isSuccess, isError, error: errorAdd} = useAddTagMembership()
  const courseStudentCount = Number(ENV.course?.course_student_count ?? 0)
  const selectedCount = allInCourse
    ? courseStudentCount - (userExceptions ? userExceptions.length : 0)
    : users.length
  const {setOnSuccess, setOnFailure} = useContext(AlertManagerContext)
  const [userTags, setUserTags] = useState<Record<number, number[]>>({})

  const handleUntag = async (tagGroupId: number) => {
    try {
      await bulkDeleteGroupMemberships(tagGroupId, users)

      MessageBus.trigger('reloadUsersTable', {})
      // need to delay a little bit so that screenreaders can read the success message
      setTimeout(() => {
        const singularMessage = I18n.t('Tag removed successfully')
        const pluralMessage = I18n.t('Tags removed successfully')
        const message = users.length > 1 ? pluralMessage : singularMessage
        setOnSuccess(message, false)
      }, 0)
    } catch (_error) {
      setTimeout(() => {
        setOnFailure(I18n.t('Tags could not be removed'), false)
      }, 0)
    }
  }

  const handleMenuSelection: HandleMenuSelection = (_e, selected) => {
    if (!allInCourse && users.length === 0 && selected !== -1) {
      setOnFailure(I18n.t('Select one or more users first'))
      return
    }

    const commonTagGroupIds = getCommonTagIds(users, userTags)

    if (Array.isArray(selected)) {
      if (selected.length > 0 && selected[0]) {
        if (commonTagGroupIds.has(Number(selected[0]))) {
          handleUntag(Number(selected[0]))
        } else {
          mutate({
            groupId: selected[0],
            ...(allInCourse ? {allInCourse, userExceptions} : {userIds: users}),
          })
        }
      }
      return
    }

    if (typeof selected === 'number') {
      if (selected === -1) {
        setIsModalOpen(true)
      } else if (selected > 0) {
        if (commonTagGroupIds.has(selected)) {
          handleUntag(selected)
        } else {
          mutate({
            groupId: selected,
            ...(allInCourse ? {allInCourse, userExceptions} : {userIds: users}),
          })
        }
      }
    }
  }

  const onTrayClose = () => {
    setIsOpen(false)
    if (manageTagsRefButton.current) manageTagsRefButton.current.focus()
  }

  useEffect(() => {
    if (users.length === 0) {
      setUserTags({})
      return
    }

    const fetchTags = async () => {
      const tagsByUser = await bulkFetchUserTags(courseId, users)
      setUserTags(tagsByUser)
    }
    fetchTags()
  }, [courseId, users])

  useEffect(() => {
    if (isSuccess) {
      MessageBus.trigger('reloadUsersTable', {})
      // need to delay a little bit so that screenreaders can read the success message
      setTimeout(() => {
        setOnSuccess(I18n.t('Tag added successfully'), false)
      }, 0)
    }
    if (isError) {
      setOnFailure(I18n.t('Error: %{error}', {error: errorAdd.message}))
    }
  }, [isSuccess, isError, setOnFailure, setOnSuccess, errorAdd])

  return (
    <>
      <Flex
        as="div"
        alignItems="center"
        justifyItems="start"
        gap="none"
        direction="row"
        width="100%"
      >
        <Flex.Item margin="xx-small">
          <Text data-testid="user-diff-tag-manager-user-count">
            {I18n.t('%{userCount} Selected', {userCount: selectedCount})}
          </Text>
        </Flex.Item>
        <Flex.Item margin="xx-small">
          <TagAsMenu
            courseId={courseId}
            handleMenuSelection={handleMenuSelection}
            userTags={userTags}
            users={users}
          />
        </Flex.Item>
        <Flex.Item margin="xx-small">
          <Button
            elementRef={ref => (manageTagsRefButton.current = ref as HTMLButtonElement)}
            onClick={() => {
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
      <DifferentiationTagTrayManager isOpen={isOpen} onClose={onTrayClose} courseID={courseId} />
      <DifferentiationTagModalManager
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        mode="create"
        differentiationTagCategoryId={undefined}
      />
    </>
  )
}
