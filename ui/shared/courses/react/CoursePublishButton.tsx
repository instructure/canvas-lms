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

import HomePagePromptContainer from '@canvas/course-homepage/react/Prompt'
import React from 'react'
import ReactDOM from 'react-dom'
import createStore from '@canvas/backbone/createStore'
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
import {useScope as useI18nScope} from '@canvas/i18n'
import * as apiClient from '@canvas/courses/courseAPIClient'
import type {BaseButtonTheme} from '@instructure/shared-types'

const I18n = useI18nScope('course_publish_button')

const CoursePublishButton = ({
  isPublished,
  courseId,
  shouldRedirect,
}: {
  isPublished: boolean
  courseId: string
  shouldRedirect: boolean
}): React.ReactElement => {
  const defaultViewStore = createStore({
    selectedDefaultView: ENV.COURSE?.default_view,
    savedDefaultView: ENV.COURSE?.default_view,
  })

  const [coursePublished, setCoursePublished, setCourseUnpublished] = useBoolean(isPublished)
  const [menuOpen, setMenuOpen, setMenuClose] = useBoolean(false)

  const handleMenuToggle = (show: boolean, _menu: Menu): void => {
    if (show && setMenuOpen instanceof Function) {
      setMenuOpen()
    } else if (!show && setMenuClose instanceof Function) {
      setMenuClose()
    }
  }

  const handleUpdatePublishSuccess = (isPublishing: boolean) => {
    if (isPublishing && setCoursePublished instanceof Function) {
      setCoursePublished()
    } else if (!isPublishing && setCourseUnpublished instanceof Function) {
      setCourseUnpublished()
    }
    if (shouldRedirect) {
      if (window.location.search.length > 0) {
        window.location.reload()
      } else {
        window.location.search = '?for_reload=1'
      }
    } else {
      showFlashSuccess(I18n.t('Course was successfully updated.'))()
    }
  }

  const handlePublish = (isPublishing: boolean) => {
    if (isPublishing) {
      const defaultView = defaultViewStore.getState().savedDefaultView
      const container = document.getElementById('choose_home_page_not_modules')
      if (container) {
        apiClient
          .getModules({courseId})
          .then(({data: modules}) => {
            if (defaultView === 'modules' && modules.length === 0) {
              ReactDOM.render(
                <HomePagePromptContainer
                  forceOpen={true}
                  store={defaultViewStore}
                  courseId={courseId}
                  wikiFrontPageTitle={ENV.COURSE?.front_page_title}
                  wikiUrl={ENV.COURSE?.pages_url}
                  returnFocusTo={document.querySelector('[data-position="course_publish_menu"]')}
                  onSubmit={() => {
                    if (defaultViewStore.getState().savedDefaultView !== 'modules') {
                      apiClient.publishCourse({
                        courseId,
                        onSuccess: () => handleUpdatePublishSuccess(true),
                      })
                    }
                  }}
                />,
                container
              )
            } else {
              apiClient.publishCourse({courseId, onSuccess: () => handleUpdatePublishSuccess(true)})
            }
          })
          .catch(_e => {
            showFlashError(I18n.t('An error occurred while fetching course modules.'))()
          })
      } else {
        // we don't have the ability to change the course home page so just publish it
        apiClient.publishCourse({courseId, onSuccess: () => handleUpdatePublishSuccess(true)})
      }
    } else {
      apiClient.unpublishCourse({courseId, onSuccess: () => handleUpdatePublishSuccess(false)})
    }
  }

  const getButtonLabel = (): React.ReactFragment => {
    return (
      <>
        {coursePublished ? I18n.t('Published') : I18n.t('Unpublished')}
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
      </>
    )
  }

  let buttonThemeOverride: Partial<BaseButtonTheme> = {
    borderStyle: 'none',
  }

  if (coursePublished) {
    buttonThemeOverride = {...buttonThemeOverride, primaryInverseColor: '#0B874B'}
  }

  return (
    <Menu
      id="course_publish_menu"
      label="course_publish_menu"
      onToggle={handleMenuToggle}
      trigger={
        <Button
          renderIcon={coursePublished ? IconPublishSolid : IconNoLine}
          color="primary-inverse"
          themeOverride={buttonThemeOverride}
        >
          {getButtonLabel()}
        </Button>
      }
    >
      <Menu.Group label={I18n.t('State')} />
      <Menu.Item
        disabled={!!coursePublished}
        onClick={() => handlePublish(true)}
        value="Publish"
        themeOverride={{
          labelColor: '#0B874B',
        }}
      >
        <Flex>
          <Flex margin="0 x-small 0 0">
            <IconPublishSolid />
          </Flex>
          {I18n.t('Publish')}
        </Flex>
      </Menu.Item>
      <Menu.Item disabled={!coursePublished} onClick={() => handlePublish(false)} value="Unpublish">
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

export default CoursePublishButton
