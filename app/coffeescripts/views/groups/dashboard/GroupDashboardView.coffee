define [
  'Backbone'
], ({View}) ->

  class GroupDashboardView extends View

    ###
    views:
      quickStartBar:
      activityFeedItems:
      dashboardAside:
    ###

    initialize: ->
      @render()

    render: ->
      @$el.html """
        <div class="container">
          <div class="row">
            <div class="span7">
              <div class="quickStartBar not-expanded border border-rbl border-round-b content-callout"></div>
              <div class="activityFeedItems v-gutter content-box border border-trbl border-round box-shadow"></div>
            </div>
            <div class="span3">
              <!-- TODO: new collection thing -->
              <h2>Collections</h2>
              <div class="kollectionIndexView"></div>
              <!-- TODO: member activity and popular views -->
            </div>
          </div>
        </div>
      """
      super
