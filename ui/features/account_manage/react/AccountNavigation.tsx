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

import React from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Pagination} from '@instructure/ui-pagination'

const I18n = useI18nScope('account_manage')
const {Page} = Pagination as any

interface Props {
  readonly currentPage: number
  readonly onPageClick: (page: number) => void
  readonly pageCount: number
}

export function AccountNavigation(props: Props) {
  const pageButtons = []

  for (let i = 1; i <= props.pageCount; i++) {
    pageButtons.push(
      <Page
        current={i === props.currentPage}
        key={i}
        onClick={() => {
          props.onPageClick(i)
        }}
      >
        {i}
      </Page>
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
