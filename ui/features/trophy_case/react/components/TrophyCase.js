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

import React, {useState} from 'react'
import {Tabs} from '@instructure/ui-tabs'
import I18n from 'i18n!trophy_case'
import CurrentTrophies from './current/index'
import PastTrophies from './past/index'

const trophies = [
  {
    trophy_key: 'four_leaf_clover',
    name: 'Lucky One',
    description: '"Luck is what happens when preparation meets opportunity."',
    unlocked_at: '2020-06-22T22:42:00+00:00'
  },
  {
    trophy_key: 'ninja',
    name: 'Unknown',
    description: 'How will you earn this trophy?',
    unlocked_at: null
  },
  {
    trophy_key: 'FooBar',
    name: 'Unknown',
    description: 'How will you earn this trophy?',
    unlocked_at: null
  },
  {
    trophy_key: 'BarBaz',
    name: 'Unknown',
    description: 'How will you earn this trophy?',
    unlocked_at: null
  }
]

export default function TrophyCase() {
  const [tab, setTab] = useState(0)

  return (
    <Tabs onRequestTabChange={(e, {index}) => setTab(index)}>
      <Tabs.Panel renderTitle={I18n.t('Current')} isSelected={tab === 0} padding="none">
        <CurrentTrophies trophies={trophies} />
      </Tabs.Panel>
      <Tabs.Panel renderTitle={I18n.t('Past')} isSelected={tab === 1} padding="none">
        <PastTrophies trophies={trophies} />
      </Tabs.Panel>
    </Tabs>
  )
}
