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

import React from 'react'
import {TextArea} from '@instructure/ui-text-area'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Rating} from '@instructure/ui-rating'

export default class SearchResult extends React.Component {
  constructor(props) {
    super(props)

    this.MAX_TOKENS = 100
  }

  elideText(text) {
    if (text.split(' ').length <= this.MAX_TOKENS) {
      return text
    }
    return text.split(' ').slice(0, this.MAX_TOKENS).join(' ') + '...'
  }

  cleanText(text) {
    // TODO: any other "cleaning"?
    return text.replace(/\\n/g, '\n')
  }

  cleanAndElideText(text) {
    return this.elideText(this.cleanText(text))
  }

  generateWikiUrl(wiki_page) {
    return `/courses/${wiki_page.context_id}/pages/${wiki_page.url}`
  }

  generateDiscussionUrl(discussion_topic) {
    return `/courses/${discussion_topic.context_id}/discussion_topics/${discussion_topic.id}`
  }

  getRelevance(record) {
    return (
      <View as="div">
        <Text>Distance: {record.distance}</Text>
      </View>
    )
  }

  render() {
    if (this.props.searchResult.wiki_page) {
      // id, wiki_id, title, body, etc.
      const wiki_page = this.props.searchResult.wiki_page
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
          <span>Course Page</span>
          <View
            as="div"
            maxHeight="200px"
            dangerouslySetInnerHTML={{__html: this.elideText(wiki_page.body)}}
          />
          {this.getRelevance(wiki_page)}
          <a href={this.generateWikiUrl(wiki_page)}>View Full Page</a>
        </View>
      )
    } else if (this.props.searchResult.discussion_topic) {
      // id, title, message, etc.
      const discussion_topic = this.props.searchResult.discussion_topic
      return (
        <View
          as="div"
          margin="small"
          padding="small"
          borderWidth="small"
          borderRadius="medium"
          shadow="resting"
        >
          <h3>{discussion_topic.title}</h3>
          <span>Discussion Topic / Announcement</span>
          <View
            as="div"
            maxHeight="200px"
            dangerouslySetInnerHTML={{__html: this.elideText(discussion_topic.message)}}
          />
          {this.getRelevance(discussion_topic)}
          <a href={this.generateDiscussionUrl(discussion_topic)}>View Full Post</a>
        </View>
      )
    } else {
      // Unknown type, just dump json
      return (
        <View as="div" margin="small" padding="small">
          <TextArea value={JSON.stringify(this.props.searchResult)} />
        </View>
      )
    }
  }
}
