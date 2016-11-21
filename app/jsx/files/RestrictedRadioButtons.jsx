define([
  'underscore',
  'react',
  'react-dom',
  'i18n!restrict_student_access',
  'jquery',
  'compiled/react_files/modules/customPropTypes',
  'compiled/models/Folder',
  'jquery.instructure_date_and_time'
], function (_, React, ReactDOM, I18n, $, customPropTypes, Folder) {

  var RestrictedRadioButtons = React.createClass({

    propTypes: {
      models: React.PropTypes.arrayOf(customPropTypes.filesystemObject).isRequired,
      radioStateChange: React.PropTypes.func
    },
    permissionOptions: [{
        ref: 'publishInput',
        text: I18n.t('Publish'),
        selectedOptionKey: 'published',
        iconClasses: 'icon-publish RestrictedRadioButtons__publish_icon',
        onChange () {
          this.updateBtnEnable();
          this.setState({selectedOption: 'published'});
        }
      }, {
        ref: 'unpublishInput',
        text: I18n.t('Unpublish'),
        selectedOptionKey: 'unpublished',
        iconClasses: 'icon-unpublish RestrictedRadioButtons__unpublish_icon',
        onChange () {
          this.updateBtnEnable();
          this.setState({selectedOption: 'unpublished'});
        }
      }, {
        ref: 'permissionsInput',
        text: I18n.t('Restricted Access'),
        selectedOptionKey: ['link_only', 'date_range'],
        iconClasses: 'icon-cloud-lock RestrictedRadioButtons__icon-cloud-lock',
        onChange () {
          var selectedOption = (this.state.unlock_at) ? 'date_range' : 'link_only';
          this.updateBtnEnable();
          this.setState({selectedOption});
        }
      }],
    restrictedOptions: [{
        ref: 'link_only',
        selectedOptionKey: 'link_only',
        getText () {
          if (this.allFolders()) {
            return I18n.t('Hidden, files inside will be available with links.');
          } else if (this.props.models.length > 1 && this.anyFolders()) {
            return I18n.t('Files and folder contents only available to students with link. Not visible in student files.');
          } else {
            return I18n.t('Only available to students with link. Not visible in student files.');
          }
        }
      }, {
        ref: 'dateRange',
        selectedOptionKey: 'date_range',
        getText () { return I18n.t('Schedule student availability'); }
      }],
    getInitialState() {
      var allAreEqual, initialState, permissionAttributes;

      permissionAttributes = ['hidden', 'locked', 'lock_at', 'unlock_at'];
      initialState = {};
      allAreEqual = this.props.models.every((model) => {
        return permissionAttributes.every((attribute) => {
          return this.props.models[0].get(attribute) === model.get(attribute) || (!this.props.models[0].get(attribute) && !model.get(attribute));
        });
      });
      if (allAreEqual) {
        initialState = this.props.models[0].pick(permissionAttributes);
        if (initialState.locked) {
          initialState.selectedOption = 'unpublished'
        } else {
          if (initialState.lock_at || initialState.unlock_at) {
            initialState.selectedOption = 'date_range'
          } else if (initialState.hidden) {
            initialState.selectedOption = 'link_only'
          } else {
            initialState.selectedOption = 'published'
          }
        };
      }
      return initialState;
    },
    componentDidMount: function () {
      return $([
        ReactDOM.findDOMNode(this.refs.unlock_at),
        ReactDOM.findDOMNode(this.refs.lock_at)]).datetime_field();
    },
    extractFormValues: function () {
      return {
        hidden: this.state.selectedOption === 'link_only',
        unlock_at: this.state.selectedOption === 'date_range' && $(ReactDOM.findDOMNode(this.refs.unlock_at)).data('unfudged-date') || '',
        lock_at: this.state.selectedOption === 'date_range' && $(ReactDOM.findDOMNode(this.refs.lock_at)).data('unfudged-date') || '',
        locked: this.state.selectedOption === 'unpublished'
      };
    },
    allFolders: function () {
      return this.props.models.every(function(model) {
        return model instanceof Folder;
      });
    },
    /*
    # Returns true if all the models passed in are folders.
    */
    anyFolders: function () {
      return this.props.models.filter(function(model) {
        return model instanceof Folder;
      }).length;
    },
    updateBtnEnable: function () {
      if (this.props.radioStateChange) {
        this.props.radioStateChange();
      };
    },
    isPermissionChecked: function (option) {
      return (this.state.selectedOption === option.selectedOptionKey) ||
             _.contains(option.selectedOptionKey, this.state.selectedOption);
    },
    renderPermissionOptions: function () {
      return this.permissionOptions.map((option, index) => {
        return (
          <div className='radio' key={index}>
            <label>
              <input
                ref={option.ref}
                type='radio'
                name='permissions'
                checked={this.isPermissionChecked(option)}
                onChange={option.onChange.bind(this)}
              />
              <i className={option.iconClasses} aria-hidden={true}></i>
              {option.text}
            </label>
          </div>
        );
      });
    },
    renderRestrictedAccessOptions: function () {
      if (this.state.selectedOption !== 'link_only' && this.state.selectedOption !== 'date_range') {
        return null;
      }

      return (
        <div style={{marginLeft: '20px'}}>
          {
            this.restrictedOptions.map((option, index) => {
              return (
                <div className='radio' key={index}>
                  <label>
                    <input
                      ref={option.ref}
                      type='radio'
                      name='restrict_options'
                      checked={this.state.selectedOption === option.selectedOptionKey}
                      onChange={() => { this.setState({selectedOption: option.selectedOptionKey});}}
                    />
                    {option.getText.bind(this)()}
                  </label>
                </div>
              );
            })
          }
        </div>
      );
    },
    renderDatePickers: function () {
      var styleObj = {};
      if (this.state.selectedOption !== 'date_range') {
        styleObj.visibility = 'hidden';
      }

      return (
        <div style={styleObj}>
          <label className='control-label dialog-adapter-form-calendar-label'>
            {I18n.t('Available From')}
          </label>
          <div className='dateSelectInputContainer controls'>
            <input
              ref='unlock_at'
              defaultValue={(this.state.unlock_at) ? $.datetimeString(this.state.unlock_at) : ''}
              className='form-control dateSelectInput'
              type='text'
              aria-label={I18n.t('Available From Date')}
            />
          </div>
          <div>
            <label className='control-label dialog-adapter-form-calendar-label'>
              {I18n.t('Available Until')}
            </label>
            <div className='dateSelectInputContainer controls'>
              <input
                id='lockDate'
                ref='lock_at'
                defaultValue={(this.state.lock_at) ? $.datetimeString(this.state.lock_at) : ''}
                className='form-control dateSelectInput'
                type='text'
                aria-label={I18n.t('Available Until Date')}
              />
            </div>
          </div>
        </div>
      );
    },
    renderRestrictedRadioButtons: function (options) {
      return (
          <div>
            {this.renderPermissionOptions()}
            {this.renderRestrictedAccessOptions()}
            {this.renderDatePickers()}
          </div>
      );
    },
    render: function () {
      return (
        <div>
              {this.renderRestrictedRadioButtons()}
        </div>
        );
    }
  });

  return RestrictedRadioButtons;

});
