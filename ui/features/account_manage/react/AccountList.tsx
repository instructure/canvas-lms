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

import React, {useState, useEffect} from 'react'
import {Spinner} from '@instructure/ui-spinner'
import {AccountNavigation} from './AccountNavigation'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {useScope as useI18nScope} from '@canvas/i18n'
import doFetchApi from '@canvas/do-fetch-api-effect'

const I18n = useI18nScope('account_manage')

const ACC_PER_PAGE = 50

interface Props {
  readonly pageIndex: number
  readonly onPageClick: (page: number) => void
}

export function AccountList(props: Props) {
  const [accounts, setAccounts] = useState([])
  const [load, setLoad] = useState(false)
  const [last, setLast] = useState(0)
  const [error, setError] = useState(false)

  useEffect(() => {
    const loadAccounts = async () => {
      setLoad(false)
      try {
        const {json, link} = await doFetchApi({
          path: '/api/v1/accounts?per_page=' + ACC_PER_PAGE + '&page=' + props.pageIndex,
          method: 'GET',
        })
        if (json !== undefined && link !== undefined) {
          setLoad(true)
          setError(false)
          setAccounts(json)
          const lastPage = parseInt(link?.last?.page, 10)
          setLast(lastPage)
        }
      } catch (err) {
        showFlashError(I18n.t('Accounts could not be loaded'))
        setLoad(true)
        setError(true)
      }
    }
    loadAccounts()
  }, [props.pageIndex])

  if (!load) {
    return (
      <div>
        <Spinner renderTitle={I18n.t('Loading')} margin="large auto 0 auto" />
      </div>
    )
  }
  if (error) {
    return <div />
  } else {
    return (
      <div>
        <ul>
          {accounts.length > 0
            ? accounts.map((item: any) => (
                <li key={item.id}>
                  <a href={'/accounts/' + item.id}>{item.name}</a>
                </li>
              ))
            : null}
        </ul>
        <AccountNavigation
          currentPage={props.pageIndex}
          onPageClick={props.onPageClick}
          pageCount={last}
        />
      </div>
    )
  }
}
