/** @jsx React.DOM */
define(function(require) {
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  var K = require('../../../constants');
  var Text = require('jsx!../../../components/text');
  var I18n = require('i18n!quiz_statistics');

  var Help = React.createClass({
    render: function() {
      return(
        <Text
          scope="discrimination_index_help"
          articleUrl={K.DISCRIMINATION_INDEX_HELP_ARTICLE_URL}>
          <p>
            This metric provides a measure of how well a single question can
            tell the difference (or discriminate) between students who do
            well on an exam and those who do not.
          </p>

          <p>
            It divides students into three groups based on their score on
            the whole quiz and displays those groups by who answered the
            question correctly.
          </p>

          <p>
            More information is available
            <a href="%{article_url}" target="_blank">here</a>.
          </p>
        </Text>
      );
    }
  });
  return Help;
});

// The above is equivalent to writing this:

I18n.t("discrimination_index_help",
  "*This metric provides a measure of how well a single question can " +
  "tell the difference (or discriminate) between students who do well on " +
  "an exam and those who do not.* " +
  "**It divides students into three " +
  "groups based on their score on the whole quiz and displays those " +
  "groups by who answered the question correctly.** " +
  "*** More information is available ****here****. ***", {
    "article_url": K.DISCRIMINATION_INDEX_HELP_ARTICLE_URL,
    "wrapper": {
        "****": "<a href=\"%{article_url}\" target=\"_blank\">$1</a>",
        "***": "<p>$1</p>",
        "**": "<p>$1</p>",
        "*": "<p>$1</p>"
    }
})