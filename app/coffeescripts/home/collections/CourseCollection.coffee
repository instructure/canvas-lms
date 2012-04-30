define ['Backbone'], ({Model, Collection}) ->

  class CourseCollection extends Collection
    model: Model.extend()
    url: 'api/v1/courses'

