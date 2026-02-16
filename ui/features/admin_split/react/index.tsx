/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import '@canvas/jquery/jquery.ajaxJSON'
import React, {useCallback, useState} from 'react'
import {Button} from '@instructure/ui-buttons'
import {IconWarningLine} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('admin_split')

interface User {
  id: string
  display_name: string
  html_url: string
  short_name?: string
}

export interface AdminSplitProps {
  user: User
  splitUrl: string
  splitUsers: User[]
}

export default function AdminSplit({
  user,
  splitUrl,
  splitUsers,
}: AdminSplitProps): React.JSX.Element {
  const [loading, setLoading] = useState(false)
  const [results, setResults] = useState<User[]>([])
  const [failed, setFailed] = useState(false)

  const performSplit = useCallback(() => {
    setLoading(true)
    $.ajaxJSON(
      splitUrl,
      'POST',
      {},
      (data: User[]) => {
        setLoading(false)
        setResults(data)
      },
      () => {
        setLoading(false)
        setFailed(true)
      },
    )
  }, [splitUrl])

  const returnToReferrer = () => {
    window.location.href = document.referrer
  }

  if (failed) {
    return (
      <p>
        <IconWarningLine />
        {I18n.t('Failed to split users.')}
      </p>
    )
  }

  if (results.length > 0) {
    return (
      <>
        <p>{I18n.t('User split complete. Links to split user accounts follow:')}</p>
        <ul>
          {results.map(u => (
            <li key={u.id}>
              <a href={`/users/${u.id}`}>{u.short_name}</a>
            </li>
          ))}
        </ul>
        {document.referrer ? (
          <Button margin="xx-small" color="primary" onClick={returnToReferrer}>
            {I18n.t('OK')}
          </Button>
        ) : null}
      </>
    )
  }

  if (splitUsers.length === 0) {
    return <p>{I18n.t('There are no user accounts to split from this user.')}</p>
  }

  return (
    <>
      <p>{I18n.t('The following users will be split into separate user accounts:')}</p>
      <ul>
        <li key={user.id}>
          <a href={user.html_url}>{user.display_name}</a>
        </li>
        {splitUsers.map(u => (
          <li key={u.id}>
            {u.display_name} ({u.id})
          </li>
        ))}
      </ul>
      <p>
        {I18n.t(
          'NOTE: This will attempt to undo the merge as fully as possible; however, merged users may not be perfectly restored to their prior state.',
        )}
      </p>
      <Button disabled={loading} margin="xx-small" color="primary" onClick={performSplit}>
        {I18n.t('Split')}
      </Button>
      {document.referrer ? (
        <Button margin="xx-small" color="secondary" onClick={returnToReferrer}>
          {I18n.t('Cancel')}
        </Button>
      ) : null}
    </>
  )
}
