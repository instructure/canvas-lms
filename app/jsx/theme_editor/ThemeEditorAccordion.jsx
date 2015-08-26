/** @jsx React.DOM */

define([
  'react',
  './ThemeEditorColorRow',
  './ThemeEditorImageRow',
  './PropTypes',
  'jquery',
  'jqueryui/accordion'
], (React, ThemeEditorColorRow, ThemeEditorImageRow, customTypes, $) => {

  return React.createClass({

    displayName: 'ThemeEditorAccordion',

    propTypes: {
      variableSchema: customTypes.variableSchema,
      brandConfigVariables: React.PropTypes.object.isRequired,
      changedValues: React.PropTypes.object.isRequired,
      changeSomething: React.PropTypes.func.isRequired,
      getDisplayValue: React.PropTypes.func.isRequired
    },

    componentDidMount() {
      $(this.getDOMNode()).accordion({
        header: "h3",
        heightStyle: "content",
        beforeActivate: function ( event, ui) {
          var previewIframe = $('#previewIframe');
          if ($.trim(ui.newHeader[0].innerText) === 'Login Screen') {
            var loginPreview = previewIframe.contents().find('#login-preview');
            if (loginPreview) previewIframe.scrollTo(loginPreview);
          } else {
            previewIframe.scrollTo(0);
          }
        }
      });
    },

    renderRow(varDef) {
      var props = {
        currentValue: this.props.brandConfigVariables[varDef.variable_name],
        userInput: this.props.changedValues[varDef.variable_name],
        onChange: this.props.changeSomething.bind(null, varDef.variable_name),
        placeholder: this.props.getDisplayValue(varDef.variable_name),
        varDef: varDef
      }
      return varDef.type === 'color' ? ThemeEditorColorRow(props) : ThemeEditorImageRow(props)
    },

    render() {
      return (
        <div className="accordion ui-accordion--mini Theme__editor-accordion">
          {this.props.variableSchema.map(variableGroup =>
            [
              <h3>
                <a href="#">
                  <div className="te-Flex">
                    <span className="te-Flex__block">{variableGroup.group_name}</span>
                    <i className="Theme__editor-accordion-icon icon-mini-arrow-right" />
                  </div>
                </a>
              </h3>
            ,
              <div>
                {variableGroup.variables.map(this.renderRow)}
              </div>
            ]
          )}
        </div>
      )
    }
  })
});
