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

import React, {useState, useEffect, useRef} from 'react'
import useBoolean from '@canvas/outcomes/react/hooks/useBoolean'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {
  IconArrowOpenDownSolid,
  IconArrowOpenUpSolid,
  IconNoLine,
  IconPublishSolid,
} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import {View} from '@instructure/ui-view'
import {showFlashSuccess, showFlashError} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {BaseButtonTheme} from '@instructure/shared-types'
import {useMutation} from '@apollo/client'
import {SET_WORKFLOW} from '@canvas/assignments/graphql/teacher/Mutations'
import {BREAKPOINTS, type Breakpoints} from '@canvas/with-breakpoints'

const I18n = createI18nScope('assignment_publish_button')
const AssignmentPublishButton = ({
  isPublished,
  assignmentLid,
  breakpoints,
}: {
  isPublished: boolean
  assignmentLid: string
  breakpoints: Breakpoints
}): React.ReactElement => {
  const [assignmentPublished, setAssignmentPublished, setAssignmentUnpublished] =
    useBoolean(isPublished)
  const [menuOpen, setMenuOpen, setMenuClose] = useBoolean(false)
  const [setWorkFlowState] = useMutation(SET_WORKFLOW)
  const [menuWidth, setMenuWidth] = useState(window.innerWidth)
  const buttonRef = useRef<HTMLButtonElement | null>(null)
  const updateMenuWidth = () => {
    if (buttonRef.current) {
      setMenuWidth(buttonRef.current.offsetWidth)
    }
  }
  useEffect(() => {
    const handleResize = () => updateMenuWidth()
    window.addEventListener('resize', handleResize)
    return () => window.removeEventListener('resize', handleResize)
  }, [])
  const buttonRefCallback = (element: HTMLButtonElement | null) => {
    buttonRef.current = element
    updateMenuWidth()
  }
  const handleMenuToggle = (show: boolean, _menu: Menu): void => {
    if (show && setMenuOpen instanceof Function) {
      setMenuOpen()
    } else if (!show && setMenuClose instanceof Function) {
      setMenuClose()
    }
  }
  const handleUpdatePublishFailure = (isPublishing: boolean) => {
    if (isPublishing) {
      showFlashError(I18n.t('This assignment has failed to publish.'))()
    } else {
      showFlashError(I18n.t('This assignment has failed to unpublish.'))()
    }
  }
  const handleUpdatePublishSuccess = (isPublishing: boolean) => {
    if (isPublishing && setAssignmentPublished instanceof Function) {
      setAssignmentPublished()
      showFlashSuccess(I18n.t('This assignment has been published.'))()
    } else if (!isPublishing && setAssignmentUnpublished instanceof Function) {
      setAssignmentUnpublished()
      showFlashSuccess(I18n.t('This assignment has been unpublished.'))()
    }
  }
  const handlePublish = async (isPublishing: boolean) => {
    const workflowState = isPublishing ? 'published' : 'unpublished'
    setWorkFlowState({variables: {id: Number(assignmentLid), workflow: workflowState}})
      .then(result => {
        if (result.errors?.length || !result.data || result.data.errors) {
          handleUpdatePublishFailure(isPublishing)
        } else if (result.data?.updateAssignment.assignment) {
          handleUpdatePublishSuccess(isPublishing)
        }
      })
      .catch(() => handleUpdatePublishFailure(isPublishing))
  }
  const getButtonLabel = (): React.ReactFragment => {
    // @ts-expect-error
    return (
      <>
        {assignmentPublished ? I18n.t('Published') : I18n.t('Unpublished')}
        {!breakpoints.mobileOnly && (
          <View margin="0 0 0 x-small">
            {menuOpen ? (
              <IconArrowOpenUpSolid
                size="x-small"
                color="primary"
                themeOverride={{
                  sizeXSmall: '0.75rem',
                }}
              />
            ) : (
              <IconArrowOpenDownSolid
                size="x-small"
                color="primary"
                themeOverride={{
                  sizeXSmall: '0.75rem',
                }}
              />
            )}
          </View>
        )}
      </>
    )
  }
  let buttonThemeOverride: Partial<BaseButtonTheme> = {
    borderStyle: 'none',
  }
  if (assignmentPublished) {
    buttonThemeOverride = {...buttonThemeOverride, primaryInverseColor: '#03893D'}
  }
  return (
    <Menu
      id="assignment_publish_menu"
      label="assignment_publish_menu"
      onToggle={handleMenuToggle}
      themeOverride={
        breakpoints.mobileOnly
          ? {minWidth: `${menuWidth}px`, maxWidth: BREAKPOINTS.mobileOnly.maxWidth}
          : undefined
      }
      withArrow={false}
      trigger={
        // @ts-expect-error
        <Button
          elementRef={buttonRefCallback}
          renderIcon={assignmentPublished ? IconPublishSolid : IconNoLine}
          color="primary-inverse"
          themeOverride={buttonThemeOverride}
          data-testid="assignment-publish-menu"
          display={breakpoints.mobileOnly && 'block'}
          margin={breakpoints.mobileOnly && 'none none small none'}
        >
          {getButtonLabel()}
        </Button>
      }
    >
      <Menu.Group label={I18n.t('State')} />
      <Menu.Item
        disabled={!!assignmentPublished}
        onClick={() => handlePublish(true)}
        value="Publish"
        themeOverride={{
          labelColor: '#03893D',
        }}
        data-testid="publish-option"
      >
        <Flex>
          <Flex margin="0 x-small 0 0">
            <IconPublishSolid />
          </Flex>
          {I18n.t('Publish')}
        </Flex>
      </Menu.Item>
      <Menu.Item
        disabled={!assignmentPublished}
        onClick={() => handlePublish(false)}
        value="Unpublish"
        data-testid="unpublish-option"
      >
        <Flex>
          <Flex margin="0 x-small 0 0">
            <IconNoLine />
          </Flex>
          {I18n.t('Unpublish')}
        </Flex>
      </Menu.Item>
    </Menu>
  )
}

export default AssignmentPublishButton
