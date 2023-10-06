/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
// @ts-expect-error
import {Provider} from 'react-redux'
import {useScope as useI18nScope} from '@canvas/i18n'
import GradebookMenu from '@canvas/gradebook-menu'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import SearchForm from './SearchForm'
import SearchResults from './SearchResults'

import GradebookHistoryStore from './store/GradebookHistoryStore'

const I18n = useI18nScope('gradebook_history')

type Props = {
  courseUrl: string
  learningMasteryEnabled?: boolean
  enhancedIndividualGradebookEnabled?: boolean
}

const GradebookHistoryApp = ({
  courseUrl,
  learningMasteryEnabled,
  enhancedIndividualGradebookEnabled,
}: Props) => (
  <Provider store={GradebookHistoryStore}>
    <div>
      <h1 className="screenreader-only">{I18n.t('Gradebook History')}</h1>

      {/* ugly negative left margin to cancel out unmodifiable InstUI button
      padding and get the menu to line up with the search form */}
      {/* EVAL-3711 Remove ICE Feature Flag */}
      <div
        style={window.ENV.FEATURES.instui_nav ? {margin: '0 0 2.25em 0'} : {margin: '0 0 1.5em 0'}}
      >
        <GradebookMenu
          courseUrl={courseUrl}
          enhancedIndividualGradebookEnabled={enhancedIndividualGradebookEnabled}
          learningMasteryEnabled={learningMasteryEnabled}
          variant="GradebookHistory"
        />
      </div>
      <SearchForm />
      <SearchResults
        caption={<ScreenReaderContent>{I18n.t('Grade Changes')}</ScreenReaderContent>}
      />
    </div>
  </Provider>
)

export default GradebookHistoryApp
