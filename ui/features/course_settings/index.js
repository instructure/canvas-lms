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
import ReactDOM from 'react-dom'
import NavigationView from './backbone/views/NavigationView'
import ErrorBoundary from '@canvas/error-boundary'
import FeatureFlagAdminView from '@canvas/feature-flag-admin-view'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import CourseColorSelector from './react/components/CourseColorSelector'
import CourseImageSelector from './react/components/CourseImageSelector'
import configureStore from './react/store/configureStore'
import initialState from './react/store/initialState'
import './jquery/index'
import '@canvas/grading-standards'
import FeatureFlags from '@canvas/feature-flags'
import I18n from 'i18n!course_settings'

const BlueprintLockOptions = React.lazy(() => import('./react/components/BlueprintLockOptions'))
const CourseTemplateDetails = React.lazy(() => import('./react/components/CourseTemplateDetails'))
const CourseAvailabilityOptions = React.lazy(() =>
  import('./react/components/CourseAvailabilityOptions')
)
const Integrations = React.lazy(() => import('@canvas/integrations/react/courses/Integrations'))

const Loading = () => <Spinner size="x-small" renderTitle={I18n.t('Loading')} />
const Error = () => (
  <div className="bcs_check-box">
    <Text color="warning">{I18n.t('Unable to load this control')}</Text>
  </div>
)

const blueprint = document.getElementById('blueprint_menu')
if (blueprint) {
  ReactDOM.render(
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
    blueprint
  )
}

const courseTemplate = document.getElementById('course_template_details')
if (courseTemplate) {
  const isEditable = courseTemplate.getAttribute('data-is-editable') === 'true'
  ReactDOM.render(
    <Suspense fallback={<Loading />}>
      <ErrorBoundary errorComponent={<Error />}>
        <CourseTemplateDetails isEditable={isEditable} />
      </ErrorBoundary>
    </Suspense>,
    courseTemplate
  )
}

const navView = new NavigationView({el: $('#tab-navigation')})

if (document.getElementById('tab-features')) {
  if (window.ENV.NEW_FEATURES_UI) {
    ReactDOM.render(<FeatureFlags disableDefaults />, document.getElementById('tab-features'))
  } else {
    const featureFlagView = new FeatureFlagAdminView({el: '#tab-features'})
    featureFlagView.collection.fetchAll()
  }
}

$(() => navView.render())

if (ENV.COURSE_IMAGES_ENABLED) {
  const courseImageStore = configureStore(initialState)

  ReactDOM.render(
    <CourseImageSelector store={courseImageStore} name="course[image]" courseId={ENV.COURSE_ID} />,
    $('.CourseImageSelector__Container')[0]
  )
}

const availabilityOptionsContainer = document.getElementById('availability_options_container')
if (availabilityOptionsContainer) {
  ReactDOM.render(
    <Suspense fallback={<Loading />}>
      <CourseAvailabilityOptions
        canManage={
          ENV.PERMISSIONS.can_manage_courses ||
          (ENV.PERMISSIONS.manage && !ENV.PREVENT_COURSE_AVAILABILITY_EDITING_BY_TEACHERS)
        }
        viewPastLocked={ENV.RESTRICT_STUDENT_PAST_VIEW_LOCKED}
        viewFutureLocked={ENV.RESTRICT_STUDENT_FUTURE_VIEW_LOCKED}
      />
    </Suspense>,
    availabilityOptionsContainer
  )
}

if (ENV.COURSE_COLORS_ENABLED) {
  const courseColorPickerContainer = document.getElementById('course_color_picker_container')
  if (courseColorPickerContainer) {
    ReactDOM.render(
      <CourseColorSelector courseColor={ENV.COURSE_COLOR} />,
      courseColorPickerContainer
    )
  }
}

const integrationsContainer = document.getElementById('tab-integrations')
if (integrationsContainer) {
  ReactDOM.render(
    <Suspense fallback={<Loading />}>
      <Integrations />
    </Suspense>,
    integrationsContainer
  )
}
