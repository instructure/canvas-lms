/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

import $ from 'jquery'
import React, {Suspense} from 'react'
import {createRoot} from 'react-dom/client'
import NavigationView from './backbone/views/NavigationView'
import ErrorBoundary from '@canvas/error-boundary'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import CourseColorSelector from './react/components/CourseColorSelector'
import CourseImageSelector from './react/components/CourseImageSelector'
import configureStore from './react/store/configureStore'
import initialState from './react/store/initialState'
import './jquery/index'
import '@canvas/grading-standards'
import {useScope as createI18nScope} from '@canvas/i18n'
import ready from '@instructure/ready'
import QuantitativeDataOptions from './react/components/QuantitativeDataOptions'
import CourseDefaultDueTime from './react/components/CourseDefaultDueTime'

const I18n = createI18nScope('course_settings')

const BlueprintLockOptions = React.lazy(() => import('./react/components/BlueprintLockOptions'))
const CourseTemplateDetails = React.lazy(() => import('./react/components/CourseTemplateDetails'))
const CourseAvailabilityOptions = React.lazy(
  () => import('./react/components/CourseAvailabilityOptions'),
)
const Integrations = React.lazy(() => import('@canvas/integrations/react/courses/Integrations'))
const CourseApps = React.lazy(() => import('./react/components/CourseApps'))

const Loading = () => <Spinner size="x-small" renderTitle={I18n.t('Loading')} />
const Error = () => (
  <div className="bcs_check-box">
    <Text color="danger">{I18n.t('Unable to load this control')}</Text>
  </div>
)

ready(() => {
  const blueprint = document.getElementById('blueprint_menu')
  if (blueprint) {
    const blueprintRoot = createRoot(blueprint)
    blueprintRoot.render(
      <Suspense fallback={<Loading />}>
        <ErrorBoundary errorComponent={<Error />}>
          <BlueprintLockOptions
            isMasterCourse={ENV.IS_MASTER_COURSE}
            disabledMessage={ENV.DISABLED_BLUEPRINT_MESSAGE}
            generalRestrictions={ENV.BLUEPRINT_RESTRICTIONS}
            useRestrictionsbyType={ENV.USE_BLUEPRINT_RESTRICTIONS_BY_OBJECT_TYPE}
            restrictionsByType={ENV.BLUEPRINT_RESTRICTIONS_BY_OBJECT_TYPE}
          />
        </ErrorBoundary>
      </Suspense>,
    )
  }

  const courseTemplate = document.getElementById('course_template_details')
  if (courseTemplate) {
    const isEditable = courseTemplate.getAttribute('data-is-editable') === 'true'

    const courseTemplateRoot = createRoot(courseTemplate)
    courseTemplateRoot.render(
      <Suspense fallback={<Loading />}>
        <ErrorBoundary errorComponent={<Error />}>
          <CourseTemplateDetails isEditable={isEditable} />
        </ErrorBoundary>
      </Suspense>,
    )
  }

  const navView = new NavigationView({el: $('#tab-navigation')})

  $(() => navView.render())

  const imageSelectorRoot = createRoot($('.CourseImageSelector__Container')[0])
  imageSelectorRoot.render(
    <CourseImageSelector
      store={configureStore(initialState)}
      courseId={ENV.COURSE_ID}
      setting="image"
    />,
  )

  const bannerImageContainer = document.getElementById('course_banner_image_selector_container')
  if (bannerImageContainer) {
    const bannerImageRoot = createRoot(bannerImageContainer)
    bannerImageRoot.render(
      <CourseImageSelector
        store={configureStore(initialState)}
        courseId={ENV.COURSE_ID}
        setting="banner_image"
        wide={true}
      />,
    )
  }

  const availabilityOptionsContainer = document.getElementById('availability_options_container')
  if (availabilityOptionsContainer) {
    const availabilityOptionsRoot = createRoot(availabilityOptionsContainer)
    availabilityOptionsRoot.render(
      <Suspense fallback={<Loading />}>
        <ErrorBoundary errorComponent={<Error />}>
          <CourseAvailabilityOptions
            canManage={ENV.PERMISSIONS.edit_course_availability}
            viewPastLocked={ENV.RESTRICT_STUDENT_PAST_VIEW_LOCKED}
            viewFutureLocked={ENV.RESTRICT_STUDENT_FUTURE_VIEW_LOCKED}
          />
        </ErrorBoundary>
      </Suspense>,
    )
  }

  const restrictQuantitativeDataContainer = document.getElementById(
    'restrict_quantitative_data_options_container',
  )
  if (restrictQuantitativeDataContainer) {
    const quantitativeDataRoot = createRoot(restrictQuantitativeDataContainer)
    quantitativeDataRoot.render(
      <Suspense fallback={<Loading />}>
        <QuantitativeDataOptions canManage={ENV.CAN_EDIT_RESTRICT_QUANTITATIVE_DATA} />
      </Suspense>,
    )
  }

  const defaultDueTimeContainer = document.getElementById('default_due_time_container')
  if (defaultDueTimeContainer) {
    const defaultDueTimeRoot = createRoot(defaultDueTimeContainer)
    defaultDueTimeRoot.render(
      <Suspense fallback={<Loading />}>
        <CourseDefaultDueTime canManage={ENV.PERMISSIONS.manage} />
      </Suspense>,
    )
  }

  if (ENV.COURSE_COLORS_ENABLED) {
    const courseColorPickerContainer = document.getElementById('course_color_picker_container')
    if (courseColorPickerContainer) {
      const courseColorRoot = createRoot(courseColorPickerContainer)
      courseColorRoot.render(<CourseColorSelector courseColor={ENV.COURSE_COLOR} />)
    }
  }

  const integrationsContainer = document.getElementById('tab-integrations')
  if (integrationsContainer) {
    const integrationsRoot = createRoot(integrationsContainer)
    integrationsRoot.render(
      <Suspense fallback={<Loading />}>
        <ErrorBoundary errorComponent={<Error />}>
          <Integrations />
        </ErrorBoundary>
      </Suspense>,
    )
  }

  const appsMountpoint = document.getElementById('tab-apps')
  if (appsMountpoint) {
    const appsRoot = createRoot(appsMountpoint)
    appsRoot.render(
      <Suspense fallback={<Loading />}>
        <ErrorBoundary errorComponent={<Error />}>
          <CourseApps />
        </ErrorBoundary>
      </Suspense>,
    )
  }
})
