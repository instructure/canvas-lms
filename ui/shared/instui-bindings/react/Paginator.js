/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import PropTypes from 'prop-types'
import I18n from 'i18n!paginator'
import {Pagination} from '@instructure/ui-pagination'
import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y-content'

const Paginator = ({loadPage, page, pageCount, ...paginationProps}) => {
  if (pageCount <= 1) {
    return <span />
  }

  return (
    <Pagination
      variant="compact"
      labelNext={I18n.t('Next Page')}
      labelPrev={I18n.t('Previous Page')}
      {...paginationProps}
    >
      {Array.from(Array(pageCount)).map((v, i) => (
        // eslint-disable-next-line react/no-array-index-key
        <Pagination.Page onClick={() => loadPage(i + 1)} key={i + 1} current={page === i + 1}>
          <PresentationContent>{i + 1}</PresentationContent>
          <ScreenReaderContent>{I18n.t('Page %{page}', {page: i + 1})}</ScreenReaderContent>
        </Pagination.Page>
      ))}
    </Pagination>
  )
}

Paginator.propTypes = {
  loadPage: PropTypes.func.isRequired,
  page: PropTypes.number.isRequired,
  pageCount: PropTypes.number.isRequired
}

export default Paginator
