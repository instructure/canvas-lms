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

/* TODO: Remove when feature flag account_level_mastery_scales is enabled */

import React, {useState, useRef} from 'react'
import {string} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Tabs} from '@instructure/ui-tabs'
import ProficiencyTable from './ProficiencyTable'
import RubricPanel from './RubricPanel'

const I18n = useI18nScope('RubricManagement')

function RubricManagement(props) {
  const [tab, setTab] = useState('tab-panel-rubrics')
  const masteryTab = useRef(null)

  function changeTab(_ev, {id}) {
    setTab(id)
  }

  function focusMasteryTab() {
    if (masteryTab.current) masteryTab.current.focus()
  }

  return (
    <Tabs onRequestTabChange={changeTab}>
      <Tabs.Panel
        renderTitle={I18n.t('Account Rubrics')}
        id="tab-panel-rubrics"
        isSelected={tab === 'tab-panel-rubrics'}
      >
        <RubricPanel />
      </Tabs.Panel>
      <Tabs.Panel
        renderTitle={I18n.t('Learning Mastery')}
        id="tab-panel-mastery"
        isSelected={tab === 'tab-panel-mastery'}
        elementRef={ref => {
          masteryTab.current = ref
        }}
      >
        <ProficiencyTable focusTab={focusMasteryTab} accountId={props.accountId} />
      </Tabs.Panel>
    </Tabs>
  )
}

RubricManagement.propTypes = {
  accountId: string.isRequired,
}

export default RubricManagement
