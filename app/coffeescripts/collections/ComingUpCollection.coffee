define ['Backbone'], ({Collection, Model}) ->

  class ComingUpCollection extends Collection

    url: '/api/v1/users/self/coming_up'

    model: Model.extend()

