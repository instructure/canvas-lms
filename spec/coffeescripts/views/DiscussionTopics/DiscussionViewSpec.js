/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import DiscussionTopicsCollection from 'compiled/collections/DiscussionTopicsCollection'
import DiscussionTopic from 'compiled/models/DiscussionTopic'
import DiscussionView from 'compiled/views/DiscussionTopics/DiscussionView'
import fakeENV from 'helpers/fakeENV'

QUnit.module('DiscussionView', {
  setup() {
    fakeENV.setup({
      permissions: {},
      discussion_topic_menu_tools: []
    })
  },
  teardown() {
    fakeENV.teardown()
  }
})

test('only displays last_reply_at if there are replies', () => {
  const discussOpts = {
    last_reply_at: '2017-09-09 12:00:00Z',
    discussion_subentry_count: 0,
    collection
  }
  const discussion = new DiscussionTopic(discussOpts, {parse: true})
  var collection = new DiscussionTopicsCollection([discussion])
  const app = new DiscussionView({model: discussion})
  ok(!app.toJSON().display_last_reply_at)
})
