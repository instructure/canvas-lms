define ['Backbone'], ({View}) ->

  class TodoItemView extends View

    tagName: 'li'

    className: 'todoItem'

    render: ->
      locals = @model.toJSON()
      assignment = locals.assignment
      @$el.html """
        <a href="#{assignment.html_url}" class="image-block">
          <span class="image-block-image" style="text-align: right; width: 30px">
            <span class="badge badget-important">#{locals.needs_grading_count}</span>
          </span>
          <span class="image-block-content">
            #{assignment.name} <span style="color: #979A9C">need grading</span>
          </span>
        </a>
      """
