define([
  'jquery',
  'react',
  'react-modal',
  'i18n!calendar_color_picker',
  'jsx/shared/CourseNicknameEdit',
  'classnames',
  'compiled/jquery.rails_flash_notifications'
], function($, React, ReactModal, I18n, CourseNicknameEdit, classnames) {

  const ReactCSSTransitionGroup = React.addons.CSSTransitionGroup

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
      this.setFocus();

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
          this.setFocus();
        }
      });
    },

    setFocus () {
      // focus course nickname input first if it's there, otherwise the first
      // color swatch
      if (this.refs.courseNicknameEdit) {
        this.refs.courseNicknameEdit.focus();
      } else if (this.refs.colorSwatch0) {
        this.refs.colorSwatch0.getDOMNode().focus();
      }
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
      var value = event.target.value || event.target.placeholder;
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

    isValidHex (color) {
      var re = /^#?([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/;
      return (re.test(color));
    },

    setCourseNickname() {
      if (this.refs.courseNicknameEdit) {
        return this.refs.courseNicknameEdit.setCourseNickname();
      }
    },

    onApply (color, event) {
      if (this.isValidHex(color)) {
        this.setState({ saveInProgress: true });

        const doneSaving = () => {
          if (this.isMounted()) {
            this.setState({
              saveInProgress: false
            });
          }
        };

        const handleSuccess = () => {
          doneSaving();
          this.closeModal();
        };

        const handleFailure = () => {
          doneSaving();
          $.flashError(I18n.t("Could not save '%{chosenColor}'", {chosenColor: this.state.currentColor}));
        };

        // both API calls update the same User model and thus need to be performed serially
        $.when(this.setColorForCalendar(color)).then( () => {
          $.when(this.setCourseNickname()).then(
            handleSuccess,
            handleFailure
          );
        },
          handleFailure
        );
      } else {
        $.flashWarning(I18n.t("'%{chosenColor}' is not a valid color.", {chosenColor: this.state.currentColor}));
      }
    },

    onCancel() {
      //reset to the cards current actual displaying color
      this.setCurrentColor(this.props.currentColor);
      this.closeModal();
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
          <CourseNicknameEdit ref='courseNicknameEdit' nicknameInfo={this.props.nicknameInfo} onEnter={this.onApply.bind(null, this.state.currentColor)} />
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

    colorPreview () {
      var previewColor = this.isValidHex(this.state.currentColor) ? this.state.currentColor : "#FFFFFF";

      if (previewColor.indexOf('#') < 0) {
        previewColor = '#' + previewColor;
      }

      var inputColorStyle = {
        color: previewColor,
        borderColor: '#d6d6d6',
        backgroundColor: previewColor
      };

      return (
        <div className = "ic-Input-group__add-on ColorPicker__ColorPreview"
             title = {this.state.currentColor}
             style = {inputColorStyle}
             role = "presentation"
             aria-hidden = "true"
             tabIndex = "-1"
        >
        { !this.isValidHex(this.state.currentColor) ?
          <i className="icon-warning" role="presentation"></i>
          :
          null
        }
        </div>
      );
    },

    pickerBody () {
      const inputClasses = classnames({
        'ic-Input': true,
        'ColorPicker__CustomInput': true,
        'ic-Input--has-warning': !this.isValidHex(this.state.currentColor)
      });

      var inputId = "ColorPickerCustomInput-" + this.props.assetString;

      return (
        <div className="ColorPicker__Container" ref="pickerBody">
          {this.prompt()}
          {this.nicknameEdit()}
          <div className  = "ColorPicker__ColorContainer"
               role       = "radiogroup"
               aria-label = {I18n.t('Select a predefined color.')} >
            {this.renderColorRows()}
          </div>

          <div className="ColorPicker__CustomInputContainer ic-Input-group">

            {this.colorPreview()}

            <label className="screenreader-only" htmlFor={inputId}>
              {I18n.t('Enter a hexcode here to use a custom color.')}
            </label>

            <input className = {inputClasses}
                   id = {inputId}
                   value = {this.state.currentColor}
                   type = 'text'
                   maxLength = "7"
                   minLength = "4"
                   ref      = "hexInput"
                   onChange = {this.setInputColor} />
          </div>

          <div className="ColorPicker__Actions">
            <button className="Button" onClick={this.onCancel}>
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
      // TODO: The non-computed styles below could possibly moved out to the
      //       proper stylesheets in the future.
      var styleObj = {
        content: {
          position: 'absolute',
          left: this.props.positions.left - 254,
          top: this.props.positions.top - 124,
          right: 0,
          bottom: 0,
          overflow: 'visible',
          padding: 0,
          borderRadius: '0'
        }
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
