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

import React from 'react'
import {render, legacyRender} from '@canvas/react'
import ModulesContainer from './react/ModulesContainer'
import ModulesStudentContainer from './react/ModulesStudentContainer'
import ready from '@instructure/ready'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv'
import ErrorBoundary from '@canvas/error-boundary'
import GenericErrorPage from '@canvas/generic-error-page/react'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import {QueryClientProvider} from '@tanstack/react-query'
import {queryClient} from '@canvas/query'
import {ContextModuleProvider} from './react/hooks/useModuleContext'
import {handleShortcutKey} from './react/utils/KBNavigator'
import ObserverOptions from '@canvas/observer-picker'
import {
  getHandleChangeObservedUser,
  autoFocusObserverPicker,
} from '@canvas/observer-picker/util/pageReloadHelper'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('context_modules_v2')

ready(() => {
  const ENV = window.ENV as GlobalEnv
  const container = document.getElementById('content')
  container?.addEventListener('keydown', handleShortcutKey)

  if (!ENV.course_id) {
    console.error(I18n.t('Course ID is required'))
    return
  }

  if (ENV.PAGE_TITLE) {
    document.title = ENV.PAGE_TITLE
  }

  if (container) {
    render(
      <ErrorBoundary
        errorComponent={
          <GenericErrorPage
            imageUrl={errorShipUrl}
            errorCategory={I18n.t('Context Modules Error Page')}
          />
        }
      >
        <QueryClientProvider client={queryClient}>
          <ContextModuleProvider
            courseId={ENV.course_id}
            isMasterCourse={ENV.MASTER_COURSE_SETTINGS?.IS_MASTER_COURSE ?? false}
            isChildCourse={ENV.MASTER_COURSE_SETTINGS?.IS_CHILD_COURSE ?? false}
            permissions={ENV.MODULES_PERMISSIONS}
            NEW_QUIZZES_ENABLED={ENV.NEW_QUIZZES_ENABLED}
            NEW_QUIZZES_BY_DEFAULT={ENV.NEW_QUIZZES_BY_DEFAULT}
            DEFAULT_POST_TO_SIS={ENV.DEFAULT_POST_TO_SIS}
            teacherViewEnabled={!!ENV?.MODULE_FEATURES?.TEACHER_MODULE_SELECTION}
            studentViewEnabled={!!ENV?.MODULE_FEATURES?.STUDENT_MODULE_SELECTION}
            restrictQuantitativeData={ENV.restrict_quantitative_data}
            isObserver={ENV.MODULES_OBSERVER_INFO?.isObserver}
            observedStudent={ENV.MODULES_OBSERVER_INFO?.observedStudent ?? null}
            moduleMenuModalTools={
              Array.isArray(ENV.MODULE_TOOLS?.module_menu_modal)
                ? ENV.MODULE_TOOLS.module_menu_modal
                : []
            }
            moduleGroupMenuTools={
              Array.isArray(ENV.MODULE_TOOLS?.module_group_menu)
                ? ENV.MODULE_TOOLS.module_group_menu
                : []
            }
            moduleMenuTools={
              Array.isArray(ENV.MODULE_TOOLS?.module_menu) ? ENV.MODULE_TOOLS.module_menu : []
            }
            moduleIndexMenuModalTools={
              Array.isArray(ENV.MODULE_TOOLS?.module_index_menu_modal)
                ? ENV.MODULE_TOOLS.module_index_menu_modal
                : []
            }
            modulesArePaginated={!!ENV.MODULE_FEATURES?.MODULES_ARE_PAGINATED}
            pageSize={ENV.MODULE_FEATURES?.PAGE_SIZE || 10}
          >
            {ENV.MODULES_PERMISSIONS?.readAsAdmin ? (
              <ModulesContainer />
            ) : (
              <ModulesStudentContainer />
            )}
          </ContextModuleProvider>
        </QueryClientProvider>
      </ErrorBoundary>,
      container,
    )

    // Mount observer dropdown to the ERB element if available
    const observerPickerContainer = document.getElementById('observer-picker-mountpoint')
    if (observerPickerContainer && ENV.OBSERVER_OPTIONS?.OBSERVED_USERS_LIST) {
      legacyRender(
        <View as="div" maxWidth="12em">
          <ObserverOptions
            autoFocus={autoFocusObserverPicker()}
            canAddObservee={!!ENV.OBSERVER_OPTIONS?.CAN_ADD_OBSERVEE}
            currentUserRoles={ENV.current_user_roles}
            currentUser={ENV.current_user}
            handleChangeObservedUser={getHandleChangeObservedUser()}
            observedUsersList={ENV.OBSERVER_OPTIONS?.OBSERVED_USERS_LIST}
            renderLabel={I18n.t('Select a student to view. The page will refresh automatically.')}
          />
        </View>,
        observerPickerContainer,
      )
    }
  }
})
