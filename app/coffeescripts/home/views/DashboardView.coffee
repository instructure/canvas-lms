define ['Backbone'], ({View}) ->

  ##
  # Top-level view of the entire dashboard
  class DashboardView extends View

    initialize: ->
      @render()

    render: ->
      @$el.html """
        <div class="container">
          <div class="row">
            <div class="span9">
              <div class="quickStartBar not-expanded border border-rbl border-round-b content-callout"></div>
              <div class="activityFeed drawerClosed"></div>
            </div>
            <div class="span3">
              <div class="dashboardActions">
                <ul class="nav nav-tabs nav-stacked">
                  <li><a href="#" class="active">Start a new class</a></li>
                  <li><a href="#">Find people on Canvas</a></li>
                  <li><a href="#">Start a Community</a></li>
                </ul>
              </div>
              <div class="dashboardAside"></div>
            </div>
          </div>
        </div>
      """
      super

