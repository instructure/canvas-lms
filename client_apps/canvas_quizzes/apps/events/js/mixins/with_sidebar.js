/** @jsx React.DOM */
define(function(require) {
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  return {
    render: function() {
      return (
        <div>
          <div id="not_right_side">
            <div id="content-wrapper">
              <div id="content" role="main" className="container-fluid">
                {this.renderContent()}
              </div>
            </div>
          </div>

          <div id="right-side-wrapper">
            <aside id="right-side" role="complementary">
              {this.renderSidebar()}
            </aside>
          </div>
        </div>
      );
    }
  }
});