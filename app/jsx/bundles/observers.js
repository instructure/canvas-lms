import ObserveeCollection from 'compiled/collections/ObserveeCollection'
import ObserverDashboardView from 'compiled/views/observers/ObserverDashboardView'

const collection = new ObserveeCollection()


collection.fetch().then(function() {
  new ObserverDashboardView({
    collection
  })
})
