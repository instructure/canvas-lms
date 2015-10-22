define([
  'jquery',
  'react',
  'react-modal',
  'i18n!calendar_color_picker',
  'jsx/shared/CourseNicknameEdit'
], function($, React, ReactModal, I18n, CourseNicknameEdit) {

  var PREDEFINED_COLORS = [
    {hexcode: '#EF4437', name: I18n.t('Red')},
    {hexcode: '#E71F63', name: I18n.t('Pink')},
    {hexcode: '#8F3E97', name: I18n.t('Purple')},
    {hexcode: '#65499D', name: I18n.t('Deep Purple')},
    {hexcode: '#4554A4', name: I18n.t('Indigo')},
    {hexcode: '#2083C5', name: I18n.t('Blue')},
    {hexcode: '#35A4DC', name: I18n.t('Light Blue')},
    {hexcode: '#09BCD3', name: I18n.t('Cyan')},
    {hexcode: '#009688', name: I18n.t('Teal')},
    {hexcode: '#43A047', name: I18n.t('Green')},
    {hexcode: '#8BC34A', name: I18n.t('Light Green')},
    {hexcode: '#FDC010', name: I18n.t('Yellow')},
    {hexcode: '#F8971C', name: I18n.t('Orange')},
    {hexcode: '#F0592B', name: I18n.t('Deep Orange')},
    {hexcode: '#F06291', name: I18n.t('Light Pink')}
  ];

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
      hideOnScroll: React.PropTypes.bool,
      positions: React.PropTypes.object,
      nonModal: React.PropTypes.bool,
      hidePrompt: React.PropTypes.bool,
      currentColor: React.PropTypes.string,
      nicknameInfo: React.PropTypes.object
    },

    // ===============
    //    LIFECYCLE
    // ===============

    getInitialState () {
      return {
        isOpen: this.props.isOpen,
        currentColor: this.props.currentColor,
        saveInProgress: false
      };
    },

    getDefaultProps () {
      return {
        currentColor: "#efefef",
        hideOnScroll: true
      }
    },

    componentDidMount () {
      // focus course nickname input first if it's there, otherwise the first
      // color swatch
      if (this.refs.courseNicknameEdit) {
        this.refs.courseNicknameEdit.focus();
      } else if (this.refs.colorSwatch0) {
        this.refs.colorSwatch0.getDOMNode().focus();
      }
      if (this.props.hideOnScroll) {
        $(window).on('scroll', this.closeModal);
      }
    },

    componentWillUnmount () {
      if (this.props.hideOnScroll) {
        $(window).off('scroll', this.closeModal);
      }
    },

    componentWillReceiveProps (nextProps) {
      this.setState({
        isOpen: nextProps.isOpen
      }, () => {
        if (this.state.isOpen) {
          this.refs.colorSwatch0.getDOMNode().focus();
        }
      });
    },

    // ===============
    //     ACTIONS
    // ===============

    closeModal () {
      if (this.isMounted()){
        this.setState({
          isOpen: false
        });


        if (this.props.afterClose) {
          this.props.afterClose()
        }
      }
    },

    setCurrentColor (color) {
      this.setState({
        currentColor: color
      });
    },

    setInputColor (event) {
      var value = event.target.value || event.srcElement.value;
      if (value.indexOf('#') < 0) {
        value = '#' + value;
      }
      event.preventDefault();
      this.setCurrentColor(value);
    },

    setColorForCalendar (color) {
      // Remove the hex if needed
      color = color.replace('#', '');

      if (color !== this.props.currentColor.replace('#', '')) {
        return $.ajax({
          url: '/api/v1/users/' + window.ENV.current_user_id + '/colors/' + this.props.assetString,
          type: 'PUT',
          data: {
            hexcode: color
          },
          success: () => {
            this.props.afterUpdateColor(color);
          },
          error: () => {
            console.log('Error setting color');
          }
        });
      }
    },

    setCourseNickname() {
      if (this.refs.courseNicknameEdit) {
        return this.refs.courseNicknameEdit.setCourseNickname();
      }
    },

    onApply (color, event) {
      this.setState({ saveInProgress: true });
      // both API calls update the same User model and thus need to be performed serially
      $.when(this.setColorForCalendar(color)).then(() => {
        $.when(this.setCourseNickname()).then(() => {
          this.closeModal();
        });
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
        var ref = "colorSwatch" + idx;
        return (
          <button className = "ColorPicker__ColorBlock"
                  ref = {ref}
                  role = "radio"
                  aria-checked = {this.state.currentColor === color.hexcode}
                  style = {colorSwatchStyle}
                  title = {title}
                  onClick = {this.setCurrentColor.bind(null, color.hexcode)}
                  key={color.hexcode}
          >
            {this.checkMarkIfMatchingColor(color.hexcode)}
            <span className="screenreader-only">{title}</span>
          </button>
        );
      });
    },

    nicknameEdit () {
      if (this.props.nicknameInfo) {
        return (
          <CourseNicknameEdit ref='courseNicknameEdit' nicknameInfo={this.props.nicknameInfo} />
        );
      }
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

      var inputId = "ColorPickerCustomInput-" + this.props.assetString;

      return (
        <div className="ColorPicker__Container">
          {this.prompt()}
          {this.nicknameEdit()}
          <div className  = "ColorPicker__ColorContainer"
               role       = "radiogroup"
               aria-label = {I18n.t('Select a predefined color.')} >
            {this.renderColorRows()}
          </div>

          <div className="ColorPicker__CustomInputContainer ic-Input-group">
            <div className = "ic-Input-group__add-on ColorPicker__ColorPreview"
                 title = {this.state.currentColor}
                 style = {inputColorStyle}
                 role = "presentation"
                 aria-hidden = "true"
                 tabIndex = "-1" />

            <label className="screenreader-only" htmlFor={inputId}>
              {I18n.t('Enter a hexcode here to use a custom color.')}
            </label>

            <input className = "ic-Input ColorPicker__CustomInput"
                   id = {inputId}
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
              onClick = {this.onApply.bind(null, this.state.currentColor)}
              disabled = {this.state.saveInProgress}>
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

      return (
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
