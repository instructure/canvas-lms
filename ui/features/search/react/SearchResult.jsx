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

import React, { useState } from 'react'
import {Text} from '@instructure/ui-text'
import {TextArea} from '@instructure/ui-text-area'
import {View} from '@instructure/ui-view'
import {Rating} from '@instructure/ui-rating'
import {Tooltip} from '@instructure/ui-tooltip'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('SmartSearch')

export default function SearchResult(props) {

  function ellipsize(str, max) {
    if (str.length > max) {
      return str.substring(0, max - 3) + '...'
    }
    return str
  }

  // Cosine distance = 1 — cosine similarity.
  // Range of cosine distance is from 0 to 2,
  // 0 — identical vectors, 1 — no correlation,
  // 2 — absolutely different.
  // We are interested in range of 0 to 1, so we
  // subtract the distance from 1 and multiply by 100.

  function getRelevance(record) {
    let relevance = 100.0 * (1.0 - record.distance)
    let tooltipText = `
      ${I18n.t('Relevance')}: ${Math.round(relevance)}%
      ${I18n.t('Distance')}: ${record.distance.toFixed(3)}
    `
    return (
        <Tooltip renderTip={tooltipText} as="span">
          <Rating label={I18n.t('Relevance')} valueNow={relevance} iconCount={5} valueMax={100} />
        </Tooltip>
    )
  }

  if (props.searchResult.content_type === 'WikiPage') {
    // id, wiki_id, title, body, etc.
    const wiki_page = props.searchResult;
    return (
      <View
        as="div"
        margin="small"
        padding="small"
        borderWidth="small"
        borderRadius="medium"
        shadow="resting"
      >
        <h3>{wiki_page.title}</h3>
        <h4>{I18n.t('Course Page')}</h4>
        <Text
          as="div"
          size="medium"
          color="secondary"
        >
          {ellipsize(wiki_page.body, 1000)}
        </Text>
        <View as="div">
          {getRelevance(wiki_page)}
        </View>
        <View as="div">
          <a href={wiki_page.html_url} target="_blank">{I18n.t('View Full Page')}</a>
        </View>
      </View>
    )
  } else if (props.searchResult.discussion_topic) {
    // TODO: implement discussion_topic or other record type
  } else {
    // Unknown type, just dump json
    return (
      <View as="div" margin="small" padding="small">
        <TextArea value={JSON.stringify(props.searchResult)} />
      </View>
    )
  }
}