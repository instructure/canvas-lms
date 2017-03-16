import AnnouncementsCollection from 'compiled/collections/AnnouncementsCollection'
import ExternalFeedCollection from 'compiled/collections/ExternalFeedCollection'
import IndexView from 'compiled/views/announcements/IndexView'
import ExternalFeedsIndexView from 'compiled/views/ExternalFeeds/IndexView'

const collection = new AnnouncementsCollection()

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
  atom_feed_url: ENV.atom_feed_url
})

collection.fetch()
