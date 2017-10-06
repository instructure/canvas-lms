/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import { array, func, string } from 'prop-types'
import I18n from 'i18n!account_course_user_search'

export default function SearchMessage({ collection, loadMore, noneFoundMessage }) {
  if (!collection || collection.loading) {
    return <div className="text-center pad-box">{I18n.t('Loading...')}</div>
  } else if (collection.error) {
    return (
      <div className="text-center pad-box">
        <div className="alert alert-error">
          {I18n.t('There was an error with your query; please try a different search')}
        </div>
      </div>
    )
  } else if (!collection.data.length) {
    return (
      <div className="text-center pad-box">
        <div className="alert alert-info">{noneFoundMessage}</div>
      </div>
    )
  } else if (collection.next) {
    return (
      <div className="text-center pad-box">
        <button className="Button--link load_more" onClick={loadMore}>
          <i className="icon-refresh" /> {I18n.t('Load more...')}
        </button>
      </div>
    )
  } else {
    return <noscript />
  }
}

SearchMessage.propTypes = {
  collection: array.isRequired,
  loadMore: func.isRequired,
  noneFoundMessage: string.isRequired
}
