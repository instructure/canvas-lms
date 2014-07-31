require [
  'compiled/views/UserObserveesView'
  'compiled/collections/UserObserveesCollection'
], (UserObserveesView, UserObserveesCollection) ->

  collection = new UserObserveesCollection
  collection.user_id = ENV['current_user_id']

  userObservees = new UserObserveesView(collection: collection)
  userObservees.render()
  userObservees.$el.appendTo('#content')

  collection.fetch()
