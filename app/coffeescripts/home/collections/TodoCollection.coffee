define ['Backbone'], ({Collection, Model}) ->

  class TodoCollection extends Collection
    url: '/api/v1/users/self/todo'
    model: Model.extend()

