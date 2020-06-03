import UserCollection from 'compiled/collections/UserCollection'
import AssignObserversView from 'compiled/views/accounts/AssignObserversView'

const collection = new UserCollection()

collection.fetch().then(function() {
  new AssignObserversView({
    collection
  })
})
