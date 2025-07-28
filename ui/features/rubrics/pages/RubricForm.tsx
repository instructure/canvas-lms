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

import React, {useEffect} from 'react'
import {Portal} from '@instructure/ui-portal'
import {RubricForm} from '@canvas/rubrics/react/RubricForm'
import {RubricBreadcrumbs} from '../components/RubricBreadcrumbs'
import {useNavigate, useParams} from 'react-router-dom'

export const Component = () => {
  const [breadcrumbMountPoint] = React.useState(
    document.querySelector('.ic-app-crumbs-enhanced-rubrics'),
  )

  const navigate = useNavigate()
  const {rubricId, accountId, courseId} = useParams()
  const navigateUrl = accountId ? `/accounts/${accountId}/rubrics` : `/courses/${courseId}/rubrics`
  const canManageRubrics = ENV.PERMISSIONS?.manage_rubrics

  useEffect(() => {
    if (breadcrumbMountPoint) {
      breadcrumbMountPoint.innerHTML = ''
    }
  }, [breadcrumbMountPoint])

  useEffect(() => {
    if (!canManageRubrics) {
      navigate(navigateUrl)
    }
  }, [canManageRubrics, navigate, navigateUrl])

  const [rubricTitle, setRubricTitle] = React.useState('')

  const mountPoint: HTMLElement | null = document.querySelector('#content')
  if (!mountPoint) {
    return null
  }

  // @ts-expect-error
  const breadCrumbs = [...ENV.breadcrumbs]
  breadCrumbs.push({name: rubricTitle, url: ''})

  return (
    <>
      <Portal open={true} mountNode={breadcrumbMountPoint}>
        <RubricBreadcrumbs breadcrumbs={breadCrumbs} />
      </Portal>
      <Portal open={true} mountNode={mountPoint}>
        <RubricForm
          rubricId={rubricId}
          accountId={accountId}
          courseId={courseId}
          // @ts-expect-error
          canManageRubrics={ENV.PERMISSIONS?.manage_rubrics}
          // @ts-expect-error
          criterionUseRangeEnabled={ENV.FEATURES.rubric_criterion_range}
          rootOutcomeGroup={ENV.ROOT_OUTCOME_GROUP}
          // @ts-expect-error
          showAdditionalOptions={ENV.enhanced_rubric_assignments_enabled}
          aiRubricsEnabled={false}
          onLoadRubric={title => setRubricTitle(title)}
          onCancel={() => navigate(navigateUrl)}
          onSaveRubric={() => navigate(navigateUrl)}
        />
      </Portal>
    </>
  )
}
