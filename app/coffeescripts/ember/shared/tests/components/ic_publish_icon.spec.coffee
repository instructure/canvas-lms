define [
  'ember'
  'underscore'
  '../../components/ic_publish_icon_component'
  '../shared_ajax_fixtures'
], (Ember, _, PublishIcon, fixtures) ->

  {run} = Ember

  fixtures.create()

  buildComponent = (props) ->
    props = _.extend props, {}
    PublishIcon.create(props)

  module 'status'


