/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var _ = require('lodash');
  var interpolate = require('../util/i18n_interpolate');
  var convertCase = require('../util/convert_case');

  var omit = _.omit;
  var underscore = convertCase.underscore;

  var InterpolatedText = React.createClass({
    render: function() {
      var container, markup, tagAttrs, options;
      if (!this.props.children) {
        return <div />;
      }

      tagAttrs = {};
      container = <div>{this.props.children}</div>;
      markup = React.renderComponentToStaticMarkup(container);
      options = omit(this.props, 'children');

      tagAttrs.dangerouslySetInnerHTML = {
        __html: interpolate(markup, underscore(options || {}))
      };

      return(
        React.DOM.div(tagAttrs)
      );
    }
  });

  var Text = React.createClass({
    getInitialState: function() {
      return {
        markup: undefined
      };
    },

    getDefaultProps: function() {
      return {
        phrase: null,
      };
    },

    //>>excludeStart("production", pragmas.production);
    componentWillReceiveProps: function(nextProps) {
      var markup;

      if (nextProps.phrase) {
        markup = React.renderComponentToStaticMarkup(InterpolatedText(nextProps));
        markup = markup.replace(/<\/?div>/g, '');

        this.setState({
          markup: markup
        });
      }
    },
    //>>excludeEnd("production");

    render: function() {
      return <div aria-role="article" dangerouslySetInnerHTML={{__html: this.state.markup }} />;
    }
  });

  return Text;
});