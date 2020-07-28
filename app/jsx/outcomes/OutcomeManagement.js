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
import React, {useState, useEffect, useMemo} from 'react'
import I18n from 'i18n!OutcomeManagement'
import {Tabs} from '@instructure/ui-tabs'
import MasteryScale from 'jsx/outcomes/MasteryScale'
import {ApolloProvider, createClient} from 'jsx/canvas-apollo'

export const OutcomePanel = () => {
  useEffect(() => {
    const container = document.getElementById('outcomes')
    if (container) {
      container.style.display = 'block'
    }

    return function cleanup() {
      if (container) {
        container.style.display = 'none'
      }
    }
  })
  return null
}

const OutcomeManagement = () => {
  const [selectedIndex, setSelectedIndex] = useState(0)

  const handleTabChange = (_, {index}) => {
    setSelectedIndex(index)
  }

  const client = useMemo(() => createClient(), [])

  const contextId = ENV.context_asset_string.split('_')[1]
  return (
    <Tabs onRequestTabChange={handleTabChange}>
      <Tabs.Panel renderTitle={I18n.t('Manage')} isSelected={selectedIndex === 0}>
        <OutcomePanel />
      </Tabs.Panel>
      <Tabs.Panel renderTitle={I18n.t('Mastery Scale')} isSelected={selectedIndex === 1}>
        <ApolloProvider client={client}>
          <MasteryScale contextType="Account" contextId={contextId} />
        </ApolloProvider>
      </Tabs.Panel>
    </Tabs>
  )
}

export default OutcomeManagement
