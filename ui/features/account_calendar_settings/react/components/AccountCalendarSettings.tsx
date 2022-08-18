/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import React, {useState} from 'react'

import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {useScope as useI18nScope} from '@canvas/i18n'

import {AccountList} from './AccountList'
import {AccountTree} from './AccountTree'
import {FilterControls, FilterType} from './FilterControls'
import {Footer} from './Footer'
import {VisibilityChange} from '../types'

const I18n = useI18nScope('account_calendar_settings')

type ComponentProps = {
  readonly accountId: number
}

const BORDER_WIDTH = 'small'

export const AccountCalendarSettings: React.FC<ComponentProps> = ({accountId}) => {
  const [visibilityChanges, setVisibilityChanges] = useState<VisibilityChange[]>([])
  const [isLoading, setLoading] = useState(false)
  const [searchValue, setSearchValue] = useState('')
  const [filterValue, setFilterValue] = useState(FilterType.SHOW_ALL)

  const onAccountToggled = (id: number, visible: boolean) => {
    const existingChange = visibilityChanges.find(change => change.id === id)
    if (existingChange) {
      if (existingChange.visible !== visible) {
        setVisibilityChanges(visibilityChanges.filter(change => change.id !== id))
      }
    } else {
      setVisibilityChanges([...visibilityChanges, {id, visible}])
    }
  }

  const onApplyClicked = () => {
    setLoading(true)
    doFetchApi({
      path: `/api/v1/accounts/${accountId}/account_calendars`,
      method: 'PUT',
      body: visibilityChanges
    })
      .then(({json}) => {
        showFlashSuccess(json?.message)()
        window.location.reload()
      })
      .catch(err => {
        showFlashError(I18n.t("Couldn't save account calendar visibilities"))(err)
        setLoading(false)
      })
  }

  const showTree = searchValue === '' && filterValue === FilterType.SHOW_ALL

  return (
    <section>
      <Heading as="h1" level="h2" margin="small 0">
        {I18n.t('Account Calendar Visibility')}
      </Heading>
      <Text>
        {I18n.t(
          'Choose which calendars your users can add in the "Other Calendars" section of their Canvas calendar. Users will only be able to add enabled calendars for the accounts they are associated with. By default, all calendars are disabled.'
        )}
      </Text>

      <View as="div" borderWidth={`${BORDER_WIDTH}`} margin="medium 0 0">
        <FilterControls
          searchValue={searchValue}
          filterValue={filterValue}
          setSearchValue={setSearchValue}
          setFilterValue={setFilterValue}
        />
      </View>
      <View as="div" borderWidth={`0 ${BORDER_WIDTH} ${BORDER_WIDTH} ${BORDER_WIDTH}`}>
        <div style={{display: showTree ? 'block' : 'none'}}>
          <AccountTree
            originAccountId={accountId}
            visibilityChanges={visibilityChanges}
            onAccountToggled={onAccountToggled}
            showSpinner={isLoading}
          />
        </div>
        <div style={{display: showTree ? 'none' : 'block'}}>
          <AccountList
            originAccountId={accountId}
            searchValue={searchValue}
            filterValue={filterValue}
            visibilityChanges={visibilityChanges}
            onAccountToggled={onAccountToggled}
          />
        </div>
      </View>
      <View
        as="div"
        borderWidth={`0 ${BORDER_WIDTH} ${BORDER_WIDTH} ${BORDER_WIDTH}`}
        background="secondary"
      >
        <Footer
          originAccountId={accountId}
          visibilityChanges={visibilityChanges}
          onApplyClicked={onApplyClicked}
          enableSaveButton={!isLoading && visibilityChanges.length > 0}
        />
      </View>
    </section>
  )
}
