/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import AnnouncementsCollection from 'compiled/collections/AnnouncementsCollection'
import ExpiredAnnouncementsCollection from 'compiled/collections/ExpiredAnnouncementsCollection'
import ExternalFeedCollection from 'compiled/collections/ExternalFeedCollection'
import IndexView from 'compiled/views/announcements/IndexView'
import ExternalFeedsIndexView from 'compiled/views/ExternalFeeds/IndexView'

const collection = new AnnouncementsCollection()

const is_teacher_or_admin = ["teacher", "admin"].some((role) => {
  return ENV.current_user_roles.includes(role)
})

const expiredCollection = is_teacher_or_admin ? new ExpiredAnnouncementsCollection() : undefined

if (ENV.permissions.create) {
  const externalFeeds = new ExternalFeedCollection()
  externalFeeds.fetch()
  new ExternalFeedsIndexView({
    permissions: ENV.permissions,
    collection: externalFeeds
  })
}

new IndexView({
  collection,
  permissions: ENV.permissions,
  atom_feed_url: ENV.atom_feed_url,
  expired_announcements: expiredCollection
})

if (expiredCollection) {
  expiredCollection.fetch().then(() => {
    collection.fetch()
  })
} else {
  collection.fetch()
}
