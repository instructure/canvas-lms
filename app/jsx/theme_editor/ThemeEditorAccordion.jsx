define([
  'react',
  'i18n!theme_editor',
  './ThemeEditorColorRow',
  './ThemeEditorImageRow',
  './RangeInput',
  './PropTypes',
  'jquery',
  'jqueryui/accordion'
], (React, I18n, ThemeEditorColorRow, ThemeEditorImageRow, RangeInput, customTypes, $) => {

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
        key: varDef.variable_name,
        currentValue: this.props.brandConfigVariables[varDef.variable_name],
        userInput: this.props.changedValues[varDef.variable_name],
        onChange: this.props.changeSomething.bind(null, varDef.variable_name),
        placeholder: this.props.getDisplayValue(varDef.variable_name),
        varDef: varDef
      };

      switch (varDef.type) {
        case 'color':
          return <ThemeEditorColorRow {...props} />
        case 'image':
          return <ThemeEditorImageRow {...props} />
        case 'percentage':
          const defaultValue = props.currentValue || props.placeholder;
          return <RangeInput
            key={varDef.variable_name}
            labelText={varDef.human_name}
            min={0}
            max={1}
            step={0.1}
            defaultValue={defaultValue ? parseFloat(defaultValue) : 0.5}
            name={'brand_config[variables][' + varDef.variable_name + ']'}
            onChange={value => props.onChange(value)}
            formatValue={value => I18n.toPercentage(value * 100, {precision: 0})}
          />
        default:
          return null
      }
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
