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

import {useScope as createI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React, {useMemo} from 'react'

import {Pagination} from '@instructure/ui-pagination'

const I18n = createI18nScope('discussion_posts')

export const NAV_BAR_HEIGHT = 64

export const ThreadPagination = props => {

  const paddingBottom = useMemo(() => {
    const urlParams = new URLSearchParams(window.location.search);
    return ENV?.SEQUENCE && urlParams.get('embed') !== 'true' ? NAV_BAR_HEIGHT : 0;
  }, [])

  return <div className="discussion-pagination-section" style={{paddingBottom}}>
    <Pagination
      margin="small"
      variant="compact"
      labelNext={I18n.t('Next Page')}
      labelPrev={I18n.t('Previous Page')}
      data-testid="pagination"
    >
      {Array.from(Array(props.totalPages)).map((v, i) => (
        <Pagination.Page
          key={btoa(i)}
          onClick={() => props.setPage(i)}
          current={props.selectedPage === i + 1}
        >
          {i + 1}
        </Pagination.Page>
      ))}
    </Pagination>
  </div>
}

ThreadPagination.propTypes = {
  setPage: PropTypes.func.isRequired,
  selectedPage: PropTypes.number.isRequired,
  totalPages: PropTypes.number.isRequired,
}
