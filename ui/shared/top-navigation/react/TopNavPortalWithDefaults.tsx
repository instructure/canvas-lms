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

import React from 'react'
import type {ITopNavProps} from '@canvas/top-navigation/react/TopNav'
import {IconStudentViewLine} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import axios from 'axios'
import {TopNavBar} from '@instructure/ui-top-nav-bar'
import {createRoot} from 'react-dom/client'
import {TopNavPortalBase, type WithProps, type Crumb, getMountPoint} from './TopNavPortalBase'
import type {ItemChild} from '@instructure/ui-top-nav-bar/types/TopNavBar/props'

const I18n = createI18nScope('discussions_v2')
const STUDENT_VIEW_URL_TEMPLATE = '/courses/{courseId}/student_view?redirect_to_referer=1'
type EnvCommon = import('@canvas/global/env/EnvCommon').EnvCommon
const isStudent = () => {
  // @ts-expect-error
  return window.ENV.current_user_roles?.includes('student') && !window.ENV.PERMISSIONS?.manage
}

const handleStudentViewClick = (studentViewUrl: string) => {
  axios
    .post(studentViewUrl)
    .then(() => {
      window.location.reload()
    })
    .catch(error => {
      console.error('Error loading student view', error)
    })
}

const handleBreadCrumbSetter = (
  {getCrumbs, setCrumbs}: {getCrumbs: () => Crumb[]; setCrumbs: (crumbs: Crumb[]) => void},
  currentPageName?: string,
) => {
  const existingCrumbs: Crumb[] = getCrumbs()
  const allCrumbs = currentPageName
    ? [...existingCrumbs, {name: currentPageName, url: ''}]
    : existingCrumbs
  setCrumbs(allCrumbs)
}

const addStudentViewActionItem = (courseId?: number) => {
  // @ts-expect-error
  const cId: number =
    courseId || window.ENV?.course?.id || window.ENV?.COURSE_ID || window.ENV?.course_id
  if (!cId) {
    return null
  }
  const studentViewUrl = STUDENT_VIEW_URL_TEMPLATE.replace('{courseId}', String(cId))
  const buttonLabel = window.ENV?.horizon_course
    ? I18n.t('View as Learner')
    : I18n.t('View as Student')
  return (
    <TopNavBar.Item
      id="student-view"
      href="#"
      variant="button"
      color="secondary"
      renderIcon={IconStudentViewLine}
      onClick={() => handleStudentViewClick(studentViewUrl)}
    >
      {buttonLabel}
    </TopNavBar.Item>
  )
}

const addTutorialActionItem = () => {
  return (
    <div
      className="TutorialToggleHolder"
      style={{
        height: '100%',
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
      }}
    />
  )
}

const tutorialEnabled = () => {
  const env = window.ENV
  // @ts-expect-error
  const new_user_tutorial_on_off = env?.NEW_USER_TUTORIALS_ENABLED_AT_ACCOUNT?.is_enabled
  return env?.NEW_USER_TUTORIALS?.is_enabled && new_user_tutorial_on_off
}

const createDefaultActionItems = (useStudentView: boolean, courseId?: number) => {
  return [
    useStudentView && !isStudent() ? addStudentViewActionItem(courseId) : null,
    tutorialEnabled() ? addTutorialActionItem() : null,
  ].filter((item): item is ItemChild => item !== null)
}

const withDefaults = (Component: React.FC<ITopNavProps>) => {
  return ({
    actionItems = [],
    currentPageName,
    getBreadCrumbSetter,
    useStudentView = false,
    courseId = undefined,
    ...props
  }: WithProps) => {
    const combinedActionItems = [
      ...createDefaultActionItems(useStudentView, courseId),
      ...actionItems,
    ]
    return (
      <Component
        getBreadCrumbSetter={crumbs =>
          getBreadCrumbSetter
            ? getBreadCrumbSetter(crumbs)
            : handleBreadCrumbSetter(crumbs, currentPageName)
        }
        actionItems={combinedActionItems}
        {...props}
      />
    )
  }
}

const TopNavPortalWithDefaults = withDefaults(TopNavPortalBase)

export const addCrumbs = (newCrumbs: Crumb[], oldCrumbs?: Crumb[]): Crumb[] => {
  const crumbs: Crumb[] = oldCrumbs || window.ENV.breadcrumbs || []
  newCrumbs.forEach(crumb => {
    if (!crumbs.some(c => c.name === crumb.name)) {
      crumbs.push(crumb)
    }
  })
  return crumbs
}
export const initializeTopNavPortalWithDefaults = (props?: WithProps): void => {
  const mountPoint = getMountPoint()
  if (mountPoint) {
    const root = createRoot(mountPoint)
    root.render(<TopNavPortalWithDefaults {...props} />)
  }
}
export default TopNavPortalWithDefaults
