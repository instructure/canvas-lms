/** @jsx React.DOM */

define([
  'jquery',
  'react',
  'react-modal',
  'i18n!calendar_color_picker',
], function($, React, ReactModal, I18n) {

  var PREDEFINED_COLORS = [
    {hexcode:'#EF4437', name: I18n.t('Red')},
    {hexcode:'#E71F63', name: I18n.t('Pink')},
    {hexcode:'#8F3E97', name: I18n.t('Purple')},
    {hexcode:'#65499D', name: I18n.t('Deep Purple')},
    {hexcode:'#4554A4', name: I18n.t('Indigo')},
    {hexcode:'#2083C5', name: I18n.t('Blue')},
    {hexcode:'#35A4DC', name: I18n.t('Light Blue')},
    {hexcode:'#09BCD3', name: I18n.t('Cyan')},
    {hexcode:'#009688', name: I18n.t('Teal')},
    {hexcode:'#43A047', name: I18n.t('Green')},
    {hexcode:'#8BC34A', name: I18n.t('Light Green')},
    {hexcode:'#FDC010', name: I18n.t('Yellow')},
    {hexcode:'#F8971C', name: I18n.t('Orange')},
    {hexcode:'#F0592B', name: I18n.t('Deep Orange')},
    {hexcode:'#F06291', name: I18n.t('Light Pink')}
  ];

  var SWATCHES_PER_ROW = 5;

  var ColorPicker = React.createClass({

    // ===============
    //     CONFIG
    // ===============

    displayName: 'ColorPicker',

    propTypes: {
      isOpen: React.PropTypes.bool,
      afterUpdateColor: React.PropTypes.func,
      afterClose: React.PropTypes.func,
      assetString: React.PropTypes.string.isRequired,
      positions: React.PropTypes.object,
      nonModal: React.PropTypes.bool,
      hidePrompt: React.PropTypes.bool,
      currentColor: React.PropTypes.string
    },

    // ===============
    //    LIFECYCLE
    // ===============

    getInitialState () {
      return {
        isOpen: this.props.isOpen,
        currentColor: this.props.currentColor
      };
    },

    getDefaultProps () {
      return {
        currentColor: "#efefef"
      }
    },

    componentDidMount () {
      if (this.refs.hexInput) {
        this.refs.hexInput.getDOMNode().focus();
      }
      $(window).on('scroll', this.closeModal);
    },

    componentWillUnmount () {
      $(window).off('scroll', this.closeModal);
    },

    componentWillReceiveProps (nextProps) {
      this.setState({
        isOpen: nextProps.isOpen
      }, () => {
        if (this.state.isOpen) {
          this.refs.hexInput.getDOMNode().focus();
        }
      });
    },

    // ===============
    //     ACTIONS
    // ===============

    closeModal () {
      this.setState({
        isOpen: false
      });

      if (this.props.afterClose) {
        this.props.afterClose()
      };
    },

    setCurrentColor (color) {
      this.setState({
        currentColor: color
      });
    },

    setInputColor (event) {
      var value = event.target.value;
      if (value.indexOf('#') < 0) {
        value = '#' + value;
      }
      event.preventDefault();
      this.setCurrentColor(value);
    },

    setColorForCalendar (color, event) {
      // Remove the hex if needed
      var color = color.replace('#', '');

      $.ajax({
        url: '/api/v1/users/' + ENV.current_user_id + '/colors/' + this.props.assetString,
        type: 'PUT',
        data: {
          hexcode: color
        },
        success: () => {
          this.props.afterUpdateColor(color);
        },
        error: () => {
          console.log('Error setting color');
        },
        complete: () => {
          this.closeModal();
        }
      });
    },

    // ===============
    //    RENDERING
    // ===============

    checkMarkIfMatchingColor (colorCode) {
      if (this.state.currentColor === colorCode) {
        return (
          <i className="icon-check"/>
        );
      }
    },

    renderColorRows () {
      return PREDEFINED_COLORS.map( (color, idx) => {
        var colorSwatchStyle = {
          borderColor: color.hexcode,
          backgroundColor: color.hexcode
        };

        var title = color.name + ' (' + color.hexcode + ')';
        return (
          <button className = "ColorPicker__ColorBlock"
                  style = {colorSwatchStyle}
                  title = {title}
                  onClick = {this.setCurrentColor.bind(null, color.hexcode)}
          >
            {this.checkMarkIfMatchingColor(color.hexcode)}
            <span className="screenreader-only">{title}</span>
          </button>
        );
      });
    },

    prompt () {
      if (!this.props.hidePrompt) {
        return (
          <div className="ColorPicker__Header">
            <h3 className="ColorPicker__Title">
              {I18n.t('Select Course Color')}
            </h3>
          </div>
        );
      }
    },

    pickerBody () {
      var inputColorStyle = {
        color: this.state.currentColor,
        borderColor: '#d6d6d6',
        backgroundColor: this.state.currentColor
      };

      return (
        <div className="ColorPicker__Container">
          {this.prompt()}
          <div className="ColorPicker__ColorContainer">
            {this.renderColorRows()}
          </div>

          <label className="screenreader-only" htmlFor="ColorPickerCustomInput">
            {I18n.t('Enter a hexcode here to use a custom color.')}
          </label>

          <div className="ColorPicker__CustomInputContainer ic-Input-group">
            <div className = "ic-Input-group__add-on ColorPicker__ColorPreview"
                 title = {this.state.currentColor}
                 style = {inputColorStyle}
                 role = "presentation"
                 aria-hidden = "true"
                 tabIndex = "-1" />

            <input className = "ic-Input ColorPicker__CustomInput"
                   id = "ColorPickerCustomInput"
                   placeholder = {this.state.currentColor}
                   type = 'text'
                   maxLength = "7"
                   minLength = "4"
                   ref      = "hexInput"
                   onChange = {this.setInputColor} />
          </div>
          <div className="ColorPicker__Actions">
            <button className="Button" onClick={this.closeModal}>
              {I18n.t('Cancel')}
            </button>
            <span>&nbsp;</span>
            <button className="Button Button--primary"
              onClick = {this.setColorForCalendar.bind(null, this.state.currentColor)}>
              {I18n.t('Apply')}
            </button>
          </div>
        </div>
      );
    },

    modalWrapping (body) {
      var styleObj = {
        position: 'absolute',
        left: this.props.positions.left - 254,
        top: this.props.positions.top - 124
      };

      return(
        <ReactModal
          ref = 'reactModal'
          style = {styleObj}
          isOpen = {this.state.isOpen}
          onRequestClose = {this.closeModal}
          className = 'ColorPicker__Content-Modal right middle horizontal'
          overlayClassName = 'ColorPicker__Overlay'
        >
          {body}
        </ReactModal>
      );
    },

    render () {
      var body = this.pickerBody();
      return this.props.nonModal ?
        body :
        this.modalWrapping(body);
    }
  });
  return ColorPicker;
});