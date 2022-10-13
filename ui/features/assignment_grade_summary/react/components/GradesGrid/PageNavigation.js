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

import React, {Component} from 'react'
import {func, number} from 'prop-types'
import {Pagination} from '@instructure/ui-pagination'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('assignment_grade_summary')

export default class PageNavigation extends Component {
  static propTypes = {
    currentPage: number.isRequired,
    onPageClick: func.isRequired,
    pageCount: number.isRequired,
  }

  shouldComponentUpdate(nextProps) {
    return Object.keys(nextProps).some(key => this.props[key] !== nextProps[key])
  }

  render() {
    const pageButtons = []

    for (let i = 1; i <= this.props.pageCount; i++) {
      pageButtons.push(
        <Pagination.Page
          current={i === this.props.currentPage}
          key={i}
          onClick={() => {
            this.props.onPageClick(i)
          }}
        >
          {I18n.n(i)}
        </Pagination.Page>
      )
    }

    return (
      <Pagination
        labelNext={I18n.t('Next Page')}
        labelPrev={I18n.t('Previous Page')}
        variant="compact"
      >
        {pageButtons}
      </Pagination>
    )
  }
}
