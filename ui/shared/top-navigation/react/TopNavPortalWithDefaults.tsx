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
import TopNavPortal from './TopNavPortal'
import {type ITopNavProps} from '@canvas/top-navigation/react/TopNav'
import type {ItemChild} from '@instructure/ui-top-nav-bar/types/TopNavBar/props'
import {IconStudentViewLine} from '@instructure/ui-icons'
import {useScope as useI18nScope} from '@canvas/i18n'
import axios from 'axios'
import type {EnvCommon} from '@canvas/global/env/EnvCommon'
import {TopNavBar} from '@instructure/ui-top-nav-bar'
import ReactDOM from 'react-dom'

const I18n = useI18nScope('discussions_v2')
const STUDENT_VIEW_URL_TEMPLATE = '/courses/{courseId}/student_view?redirect_to_referer=1'
type Crumb = Exclude<EnvCommon['breadcrumbs'], undefined>[number]
const getMountPoint = (): HTMLElement | null => document.getElementById('react-instui-topnav')
interface WithProps extends ITopNavProps {
  actionItems?: ItemChild[]
  currentPageName?: string
  useTutorial?: boolean
  useStudentView?: boolean
  courseId?: number
}

const isStudent = () => {
  // @ts-ignore
  return window.ENV.current_user_roles?.includes('student') && !window.ENV.PERMISSIONS?.manage
}

const handleStudentViewClick = (studentViewUrl: string) => {
  axios
    .post(studentViewUrl)
    .then(() => {
      window.location.reload()
    })
    .catch(error => {
      // eslint-disable-next-line no-console
      console.error('Error loading student view', error)
    })
}

const handleBreadCrumbSetter = (
  {getCrumbs, setCrumbs}: {getCrumbs: () => Crumb[]; setCrumbs: (crumbs: Crumb[]) => void},
  currentPageName?: string
) => {
  const existingCrumbs: Crumb[] = getCrumbs()
  const pageName: string = currentPageName || ''
  setCrumbs([...existingCrumbs, {name: pageName, url: ''}])
}

const addStudentViewActionItem = (courseId?: number) => {
  // @ts-ignore
  const cId: number = courseId || window.ENV?.course?.id || window.ENV?.COURSE_ID
  if (!cId) {
    return null
  }
  const studentViewUrl = STUDENT_VIEW_URL_TEMPLATE.replace('{courseId}', String(cId))
  return (
    <TopNavBar.Item
      id="student-view"
      href="#"
      variant="button"
      color="secondary"
      renderIcon={IconStudentViewLine}
      onClick={() => handleStudentViewClick(studentViewUrl)}
    >
      {I18n.t('View as Student')}
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

const createDefaultActionItems = (
  useStudentView: boolean,
  useTutorial: boolean,
  courseId?: number
) => {
  return [
    useStudentView && !isStudent() ? addStudentViewActionItem(courseId) : null,
    useTutorial ? addTutorialActionItem() : null,
  ].filter((item): item is ItemChild => item !== null)
}

const withDefaults = (Component: React.FC<ITopNavProps>) => {
  return ({
    actionItems = [],
    currentPageName,
    getBreadCrumbSetter,
    useTutorial = false,
    useStudentView = false,
    courseId = undefined,
    ...props
  }: WithProps) => {
    const combinedActionItems = [
      ...createDefaultActionItems(useStudentView, useTutorial, courseId),
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

const TopNavPortalWithDefaults = withDefaults(TopNavPortal)
export const initializeTopNavPortalWithDefaults = (props?: WithProps): void => {
  const mountPoint = getMountPoint()
  if (mountPoint) {
    ReactDOM.render(<TopNavPortalWithDefaults {...props} />, mountPoint)
  }
}
export default TopNavPortalWithDefaults
