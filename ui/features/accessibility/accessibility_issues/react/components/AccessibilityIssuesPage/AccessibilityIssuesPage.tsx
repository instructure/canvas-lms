/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {useEffect, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'

import AccessibilityIssuesContent from '../../../../shared/react/components/AccessibilityIssuesContent'
import {useAccessibilityIssueSelect} from '../../../../shared/react/hooks/useAccessibilityIssueSelect'
import {useAccessibilityScansFetchUtils} from '../../../../shared/react/hooks/useAccessibilityScansFetchUtils'
import {useAccessibilityScansStore} from '../../../../shared/react/stores/AccessibilityScansStore'
import {AccessibilityResourceScan} from '../../../../shared/react/types'
import {findById} from '../../../../shared/react/utils/apiData'

const I18n = createI18nScope('accessibility_issues')

type IssuesPageProps = {
  courseId: string
  issueId: string
}
const AccessibilityIssuesPage: React.FC<IssuesPageProps> = ({courseId: _courseId, issueId}) => {
  const [selectedItem, setSelectedItem] = useState<AccessibilityResourceScan | null>(null)
  const [loading, setLoading] = useState(true)
  const {selectIssue} = useAccessibilityIssueSelect()
  const {doFetchAccessibilityScanData} = useAccessibilityScansFetchUtils()
  const scans = useAccessibilityScansStore(state => state.accessibilityScans)

  useEffect(() => {
    async function load() {
      let localScans = scans

      if (!localScans) {
        await doFetchAccessibilityScanData({page: 1, pageSize: 50})
        localScans = useAccessibilityScansStore.getState().accessibilityScans
      }
      if (localScans && issueId) {
        const item = findById(localScans, issueId)
        setSelectedItem(item || null)
        if (item) {
          selectIssue(item, false)
        }
      }
      setLoading(false)
    }

    load()
  }, [issueId, scans, selectIssue, doFetchAccessibilityScanData])

  return (
    <View as="div">
      {loading && (
        <View margin="auto">
          <Spinner renderTitle={I18n.t('Loading accessibility issue...')} />
        </View>
      )}
      <View width="100%" height="100%" display="flex">
        {!loading && selectedItem && (
          <AccessibilityIssuesContent
            item={selectedItem}
            onClose={() => setSelectedItem(null)}
            pageView
          />
        )}
      </View>
    </View>
  )
}

export default AccessibilityIssuesPage
