define ['Backbone'], ({View}) ->

  ##
  # Base class for all ActivityFeedItems. To create a new type,
  # extend this class and set the subclass as a property of
  # this class.
  #
  #     class ActivityFeedItemView.SomeNewType extends ActivityFeedItemView
  #
  # Then make sure the activityFeedItemViewFactory module
  # requires the new base class.
  class ActivityFeedItemView extends View

    tagName: 'li'

    className: 'activityFeedItem'

    ##
    # Subclasses need to define their own `renderContent` method and
    # return a string to use in the content area of a feed item.
    renderContent: (locals) ->
      """
        #{locals.message}
        <dl class="dl-horizontal">
          #{("<dt>#{key}</dt><dd>#{val}</dd>" for own key, val of locals).join('')}
        </dl>
      """

    ##
    # Returns an object of strings to use in the rendered template.
    # All sub-classes need to return a header and subHeader property
    # becuase they are used in the shared render method.
    toJSON: ->
      locals = @model.toJSON()
      locals.header = locals.title
      locals.subHeader = locals.type
      locals

    renderAvatar: ->
      "<img src='http://placekitten.com/42/42/'>"

    ##
    # Shared layout
    render: ->
      locals = @toJSON()
      @$el.html """
        <div class="image-block">
          <div class="image-block-image">
            #{@renderAvatar()}
          </div>
          <div class="image-block-content">
            <div class="triangle-box-with-header">
              <header class="box-header">
                <div class="activityFeedItemTitle">#{locals.header}</div>
                <div class="triangle-box-subheader">#{locals.subHeader}</div>
              </header>
              <div class="box-content">
                #{@renderContent locals}
              </div>
            </div>
          </div>
        </div>
      """
      @$el.addClass locals.type.toLowerCase()
      super

