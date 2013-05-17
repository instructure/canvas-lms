require [
  'compiled/collections/DiscussionTopicsCollection'
  'compiled/collections/AnnouncementsCollection'
  'compiled/collections/ExternalFeedCollection'
  'compiled/views/DiscussionTopics/IndexView'
  'compiled/views/ExternalFeeds/IndexView'
], (DiscussionTopicsCollection, AnnouncementsCollection, ExternalFeedCollection, IndexView, ExternalFeedsIndexView) ->

  if ENV.is_showing_announcements
    collection = new AnnouncementsCollection

    if ENV.permissions.create
      externalFeeds = new ExternalFeedCollection
      externalFeeds.fetch()
      new ExternalFeedsIndexView
        permissions: ENV.permissions
        collection: externalFeeds

  else
    collection = new DiscussionTopicsCollection

  collection.fetch()

  new IndexView
    collection: collection
    permissions: ENV.permissions
    atom_feed_url: ENV.atom_feed_url
