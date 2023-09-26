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
import {TextArea} from '@instructure/ui-text-area'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Rating} from '@instructure/ui-rating'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('SmartSearch')

export default function SearchResult(props) {
  const MAX_TOKENS = 100

  function elideText(text) {
    if (text.split(' ').length <= MAX_TOKENS) {
      return text
    }
    return text.split(' ').slice(0, MAX_TOKENS).join(' ') + '...'
  }

  function cleanText(text) {
    // TODO: any other "cleaning"?
    return text.replace(/\\n/g, '\n')
  }

  function cleanAndElideText(text) {
    return elideText(cleanText(text))
  }

  function generateWikiUrl(wiki_page) {
    return `/courses/${wiki_page.context_id}/pages/${wiki_page.url}`
  }

  function generateDiscussionUrl(discussion_topic) {
    return `/courses/${discussion_topic.context_id}/discussion_topics/${discussion_topic.id}`
  }

  // TODO: Make this more user friendly and add I18n
  function getRelevance(record) {
    return (
      <View as="div">
        <Text>Distance: {record.distance}</Text>
      </View>
    )
  }

  if (props.searchResult.wiki_page) {
    // id, wiki_id, title, body, etc.
    const wiki_page = props.searchResult.wiki_page
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
        <span>{I18n.t('Course Page')}</span>
        <View
          as="div"
          maxHeight="200px"
          dangerouslySetInnerHTML={{__html: elideText(wiki_page.body)}}
        />
        {getRelevance(wiki_page)}
        <a href={generateWikiUrl(wiki_page)}>{I18n.t('View Full Page')}</a>
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
