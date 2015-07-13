/** @jsx React.DOM */

define([
  'react',
  './PropTypes',
  'i18n!theme_editor',
  'compiled/util/rgb2hex'
], (React, customTypes, I18n, rgb2hex) => {

  return React.createClass({

    displayName: 'ThemeEditorColorRow',

    propTypes: {
      varDef: customTypes.color,
      onChange: React.PropTypes.func.isRequired,
      userInput: customTypes.userColorInput,
      placeholder: React.PropTypes.string.isRequired
    },

    getDefaultProps(){
      return ({
        userInput: {}
      })
    },

    getInitialState(){
      return {};
    },

    warningLabel(){
      if (this.props.userInput.invalid && this.inputNotFocused()) {
        return(
          <div className="ic-Form-message ic-Form-message--error">
            <div className="ic-Form-message__Layout">
              <i className="icon-warning" role="presentation"></i>
              {I18n.t("'%{chosenColor}' is not a valid color.", {chosenColor: this.props.userInput.val})}
            </div>
          </div>
        )
      };
    },

    changedColor(value) {
      return $('<span>').css('background-color', value).css('background-color');
    },

    hexVal(colorString) {
      var rbgVal = this.changedColor(colorString);
      return rgb2hex(rbgVal);
    },

    invalidHexString(colorString) {
      return colorString.match(/#/) ?
        !colorString.match(/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/) :
        false
    },

    inputChange(value) {
      var invalidColor = !!value && (!this.changedColor(value) || this.invalidHexString(value));
      this.props.onChange(value, invalidColor);
    },

    inputNotFocused() {
      return this.refs.textInput && this.refs.textInput.getDOMNode() != document.activeElement
    },

    updateIfMounted() {
      if (this.isMounted()) {
        this.forceUpdate()
      }
    },

    textColorInput(){
      var cx = React.addons.classSet;
      var inputClasses = cx({
        'Theme__editor-color-block_input-text': true,
        'Theme__editor-color-block_input': true,
        'Theme__editor-color-block_input--has-error': this.props.userInput.invalid
      });

      var colorVal = this.props.userInput.val != null ? this.props.userInput.val : this.props.currentValue

      // 1st input is hidden and posts a valid hex value
      // 2nd input handles display, input events, and validation
      return(
        <span>
          <input
              type="hidden"
              name={'brand_config[variables]['+ this.props.varDef.variable_name +']'}
              value={this.hexVal(colorVal)} />
          <input
              ref="textInput"
              type="text"
              className={inputClasses}
              placeholder={this.props.placeholder}
              value={colorVal}
              onChange={event => this.inputChange(event.target.value) }
              onBlur={this.updateIfMounted} />
        </span>
      );
    },

    render() {
      return (
        <section className="Theme__editor-accordion_element Theme__editor-color ic-Form-control">
          <div className="Theme__editor-form--color">
            <label
              htmlFor={'brand_config[variables]['+ this.props.varDef.variable_name +']'}
              className="Theme__editor-color_title"
            >
              {this.props.varDef.human_name}
            </label>
            <div className="Theme__editor-color-block">
              {this.textColorInput()}
              {this.warningLabel()}
              <label className="Theme__editor-color-label Theme__editor-color-block_label-sample" style={{backgroundColor: this.props.placeholder}}
                /* this <label> and <input type=color> are here so if you click the 'sample',
                it will pop up a color picker on browsers that support it */
              >
                <input
                  className="Theme__editor-color-block_input-sample Theme__editor-color-block_input"
                  type="color"
                  ref="colorpicker"
                  value={this.props.placeholder}
                  role="presentation-only"
                  onChange={event => this.inputChange(event.target.value) } />
              </label>
            </div>
          </div>
        </section>
      )
    }
  })
});