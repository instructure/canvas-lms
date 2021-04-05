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
import React, {useState, useEffect, useMemo, useRef} from 'react'
import I18n from 'i18n!OutcomeManagement'
import {Tabs} from '@instructure/ui-tabs'
import MasteryScale from './MasteryScale/index'
import MasteryCalculation from './MasteryCalculation/index'
import {ApolloProvider, createClient} from '@canvas/apollo'
import OutcomesContext, {getContext} from '@canvas/outcomes/react/contexts/OutcomesContext'
import ManagementHeader from './ManagementHeader'
import OutcomeManagementPanel from './Management/index'

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

export const OutcomeManagementWithoutGraphql = () => {
  const improvedManagement = ENV?.IMPROVED_OUTCOMES_MANAGEMENT
  const [selectedIndex, setSelectedIndex] = useState(() => {
    const tabs = {'#mastery_scale': 1, '#mastery_calculation': 2}
    return window.location.hash in tabs ? tabs[window.location.hash] : 0
  })

  // Need to use a ref because a when normal setState is changed, this component will render
  // By rendering again, the handleTabChange will be a new function.
  // If we pass a new function to Tabs onRequestTabChange prop, it will recreate
  // the childs components, and we don't want that
  const hasUnsavedChangesRef = useRef(false)
  const setHasUnsavedChanges = hasUnsavedChanges =>
    (hasUnsavedChangesRef.current = hasUnsavedChanges)

  const handleTabChange = (_, {index}) => {
    if (hasUnsavedChangesRef.current) {
      /* eslint-disable no-restricted-globals */
      /* eslint-disable no-alert */
      if (
        confirm(I18n.t('Are you sure you want to proceed? Changes you made will not be saved.'))
      ) {
        /* eslint-enable no-restricted-globals */
        /* eslint-enable no-alert */
        setHasUnsavedChanges(false)
        setSelectedIndex(index)
      }
    } else {
      setSelectedIndex(index)
    }
  }

  // close tab / load link
  useEffect(() => {
    const onBeforeUnload = e => {
      if (hasUnsavedChangesRef.current) {
        e.preventDefault()
        e.returnValue = true
      }
    }

    window.addEventListener('beforeunload', onBeforeUnload)
    return () => {
      window.removeEventListener('beforeunload', onBeforeUnload)
    }
  }, [hasUnsavedChangesRef])

  return (
    <OutcomesContext.Provider value={getContext()}>
      {improvedManagement && <ManagementHeader />}
      <Tabs onRequestTabChange={handleTabChange}>
        <Tabs.Panel renderTitle={I18n.t('Manage')} isSelected={selectedIndex === 0}>
          {improvedManagement ? <OutcomeManagementPanel /> : <OutcomePanel />}
        </Tabs.Panel>
        <Tabs.Panel renderTitle={I18n.t('Mastery')} isSelected={selectedIndex === 1}>
          <MasteryScale onNotifyPendingChanges={setHasUnsavedChanges} />
        </Tabs.Panel>
        <Tabs.Panel renderTitle={I18n.t('Calculation')} isSelected={selectedIndex === 2}>
          <MasteryCalculation onNotifyPendingChanges={setHasUnsavedChanges} />
        </Tabs.Panel>
      </Tabs>
    </OutcomesContext.Provider>
  )
}

const OutcomeManagement = () => {
  const client = useMemo(() => createClient(), [])

  return (
    <ApolloProvider client={client}>
      <OutcomeManagementWithoutGraphql />
    </ApolloProvider>
  )
}

export default OutcomeManagement
