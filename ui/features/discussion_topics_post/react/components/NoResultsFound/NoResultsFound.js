/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import React, {useContext} from 'react'
import {Img} from '@instructure/ui-img'
import {Billboard} from '@instructure/ui-billboard'

import {SearchContext} from '../../utils/constants'

import pageNotFound from '@canvas/images/PageNotFoundPanda.svg'

const I18n = useI18nScope('discussion_posts')

export const NoResultsFound = () => {
  const {searchTerm} = useContext(SearchContext)
  return (
    <Billboard
      size="medium"
      heading="No Results Found"
      message={I18n.t('No results match "%{searchTerm}"', {searchTerm})}
      hero={
        <Img
          data-testid="page-not-found-panda"
          display="block"
          src={pageNotFound}
          alt="No results found"
        />
      }
    />
  )
}
