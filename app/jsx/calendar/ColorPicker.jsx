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

  var ColorPicker = React.createClass({
    displayName: 'ColorPicker',

    propTypes: {
      isOpen: React.PropTypes.bool,
      afterUpdateColor: React.PropTypes.func,
      assetString: React.PropTypes.string.isRequired,
      positions: React.PropTypes.object.isRequired
    },

    getInitialState () {
      return {
        isOpen: this.props.isOpen,
        inputColor: '#fff'
      };
    },

    componentDidMount () {
      this.refs.closeBtn.getDOMNode().focus();
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
          this.refs.closeBtn.getDOMNode().focus();
        }
      });
    },

    closeModal () {
      this.setState({
        isOpen: false
      });
    },

    setInputColor (event) {
      var value = event.target.value;
      if (value.indexOf('#') < 0) {
        value = '#' + value;
      }
      event.preventDefault();
      this.setState({
        inputColor: value
      });
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
          this.setState({
            inputColor: '#fff'
          });
        },
        error: () => {
          console.log('Error setting color');
        },
        complete: () => {
          this.closeModal();
        }

      });
    },

    renderColorRows () {
      return PREDEFINED_COLORS.map( (color, index) => {
        var styleObj = {
          color: color.hexcode,
          borderColor: color.hexcode,
          backgroundColor: color.hexcode
        };
        var title = color.name + ' (' + color.hexcode + ')';
        if (index % 5 === 0) {
          return (
            <span>
              <br />
              <button className="ColorPicker__ColorBlock" style={styleObj} title={title} onClick={this.setColorForCalendar.bind(null, color.hexcode)}>
                <span className="screenreader-only">{title}</span>
              </button>
            </span>
          );
        }
        return (
          <button className="ColorPicker__ColorBlock" style={styleObj} title={title} onClick={this.setColorForCalendar.bind(null, color.hexcode)}>
            <span className="screenreader-only">{title}</span>
          </button>
        );
      });
    },

    render () {
      var styleObj = {
        position: 'absolute',
        left: this.props.positions.left - 216,
        top: this.props.positions.top - 101
      };

      var inputColorStyle = {
        color: this.state.inputColor,
        borderColor: '#d6d6d6',
        backgroundColor: this.state.inputColor
      };

      return (
        <ReactModal
          ref='reactModal'
          style={styleObj}
          isOpen={this.state.isOpen}
          onRequestClose={this.closeModal}
          className='ColorPicker__Content-Modal right middle horizontal'
          overlayClassName='ColorPicker__Overlay'
        >
          <div className="ColorPicker__Container">
            <div className="ColorPicker__Header">
              <span className="ColorPicker__Title">
                {I18n.t('Select Course Color')}
              </span>
              <a ref="closeBtn" href="#" role="button" className="ColorPicker__CloseBtn" onClick={this.closeModal} aria-label={I18n.t('Close Picker')}>
                <i className="icon-x" />
              </a>
            </div>
            <div className="ColorPicker__ColorContainer">
              {this.renderColorRows()}
            </div>
            <hr className="ColorPicker__Separator" />
            <label className="screenreader-only" htmlFor="ColorPickerCustomInput">
              {I18n.t('Enter a hexcode here to use a custom color.')}
            </label>
            <div className="ColorPicker__CustomInputContainer ic-Input-group">
              <div className="ic-Input-group__add-on ColorPicker__ColorPreview"  title={this.state.inputColor} style={inputColorStyle} role="presentation" aria-hidden="true" tabIndex="-1"> </div>
              <input className="ic-Input ColorPicker__CustomInput" id="ColorPickerCustomInput" placeholder='#efefef' type='text' maxLength="7" minLength="4" onChange={this.setInputColor}/>
              <button className="Button Button--primary" onClick={this.setColorForCalendar.bind(null, this.state.inputColor)}>{I18n.t('Apply')}</button>
            </div>

          </div>
        </ReactModal>
      );
    }
  });

  return ColorPicker;


});