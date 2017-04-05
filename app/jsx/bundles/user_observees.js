import UserObserveesView from 'compiled/views/UserObserveesView'
import UserObserveesCollection from 'compiled/collections/UserObserveesCollection'

const collection = new UserObserveesCollection()
collection.user_id = ENV.current_user_id

const userObservees = new UserObserveesView({collection})
userObservees.render()
userObservees.$el.appendTo('#content')

collection.fetch()
