/** @jsx React.DOM */
define(function(require) {
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');

  /**
   * @class Components.SightedUserContent
   *
   * A component that *tries* to hide itself from screen-readers, absolutely
   * expecting that you're providing a more accessible version of the resource
   * using something like a ScreenReaderContent component.
   *
   * Be warned that this does not totally prevent all screen-readers from
   * seeing this content in all modes. For example, VoiceOver in OS X will
   * still see this element when running in the "Say-All" mode and read it
   * along with the accessible version you're providing.
   *
   * > **Warning**
   * >
   * > Use of this component is discouraged unless there's no alternative!!!
   * >
   * > The only one case that justifies its use is when design provides a
   * > totally inaccessible version of a resource, and you're trying to
   * > accommodate the design (for sighted users,) and provide a genuine layer
   * > of accessibility (for others.)
   */
  var SightedUserContent = React.createClass({
    getDefaultProps: function() {
      return {
        tagName: 'span'
      };
    },

    render: function() {
      var tagFactory = React.DOM[this.props.tagName];

      return this.transferPropsTo(tagFactory({
        // HTML5 [hidden] works in many screen-readers and in some cases, like
        // VoiceOver's Say-All mode, is the only thing that works for skipping
        // content. However, this clearly has the downside of hiding the
        // content from sighted users as well, so we resort to CSS to get the
        // items back into display and we win-win.
        'hidden': true,
        'aria-hidden': true,
        'role': 'presentation',
        'aria-role': 'presentation',
        'className': 'sighted-user-content'
      }, this.props.children));
    }
  });

  return SightedUserContent;
});