/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {View} from '@instructure/ui-view'
import {CloseButton} from '@instructure/ui-buttons'
// import {List} from '@instructure/ui-list'
import {Text} from '@instructure/ui-text'
import React, {useEffect} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {SummarizedChange} from '../utils/change_tracking'

const I18n = useI18nScope('unpublished_changes_tray_contents')

// the INSTUI <List as="ol"> has a bug where the item numbering
// is not in a hanging indent, so when list items wrap they
// wrap all the way under the number, which does not look correct.
// This styles a vanilla html OL until INSTUI fixes their bug.
function styleList() {
  if (document.getElementById('course_pace_changes_list_style')) return
  const styl = document.createElement('style')
  styl.id = 'course_pace_changes_list_style'
  styl.textContent = `
  ol.course_pace_changes {
    margin: 0 0 1.5rem;
    padding: 0;
    counter-reset: item;
  }

  ol.course_pace_changes>li {
    margin: 0 0 .5rem 2rem;
    text-indent: -2rem;
    list-style-type: none;
    counter-increment: item;
  }

  ol.course_pace_changes>li::before {
    display: inline-block;
    width: 1.5rem;
    margin-inline-end: 0.5rem;
    font-weight: bold;
    text-align: right;
    content: counter(item) ".";
  }
  `
  document.head.appendChild(styl)
}

// Doing this to avoid TS2339 errors-- remove once we're on InstUI 8
// const {Item} = List as any

export type UnpublishedChangesTrayProps = {
  changes?: SummarizedChange[]
  handleTrayDismiss: () => void
}

const UnpublishedChangesTrayContents = ({
  changes = [],
  handleTrayDismiss
}: UnpublishedChangesTrayProps) => {
  useEffect(() => {
    styleList()
  }, [])

  return (
    <View as="div" width="20rem" margin="0 auto large" padding="small">
      <CloseButton
        placement="end"
        offset="small"
        onClick={handleTrayDismiss}
        screenReaderLabel={I18n.t('Close')}
      />
      <View as="header" margin="0 0 medium">
        <h4>
          <Text weight="bold">{I18n.t('Unpublished Changes')}</Text>
        </h4>
      </View>
      <ol className="course_pace_changes">
        {changes.map(c => c.summary && <li key={c.id}>{c.summary}</li>)}
      </ol>
    </View>
  )
}

export default UnpublishedChangesTrayContents
