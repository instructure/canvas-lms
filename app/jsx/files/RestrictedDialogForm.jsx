define([
  'underscore',
  'react',
  'i18n!restrict_student_access',
  'jquery',
  'classnames',
  'jsx/files/UsageRightsSelectBox',
  'jsx/files/DialogPreview',
  'compiled/react_files/components/RestrictedDialogForm'
], function (_, React, I18n, $, classNames, UsageRightsSelectBox, DialogPreview, RestrictedDialogForm) {

  RestrictedDialogForm.PERMISSION_OPTIONS = [{
    ref: 'publishInput',
    text: I18n.t('Publish'),
    selectedOptionKey: 'published',
    onChange () {
      this.setState({selectedOption: 'published'});
    }
  }, {
    ref: 'unpublishInput',
    text: I18n.t('Unpublish'),
    selectedOptionKey: 'unpublished',
    onChange () {
      this.setState({selectedOption: 'unpublished'});
    }
  }, {
    ref: 'permissionsInput',
    text: I18n.t('Restricted Access'),
    selectedOptionKey: ['link_only', 'date_range'],
    onChange () {
      var selectedOption = (this.state.unlock_at) ? 'date_range' : 'link_only';
      this.setState({selectedOption});
    }
  }];

  RestrictedDialogForm.RESTRICTED_OPTIONS = [{
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
  }];

  RestrictedDialogForm.isPermissionChecked = function (option) {
    return (this.state.selectedOption === option.selectedOptionKey) ||
           _.contains(option.selectedOptionKey, this.state.selectedOption);
  };

  RestrictedDialogForm.renderUsageRightsWarning = function () {
    return (
      <div className='RestrictedDialogForm__banner col-xs-12'>
        <span className='alert'>
          <i className='icon-warning RestrictedDialogForm__warning'></i>
          {I18n.t('Before publishing, you must set usage rights on your files.')}
        </span>
      </div>
    );
  };

  RestrictedDialogForm.renderPermissionOptions = function () {
    return this.PERMISSION_OPTIONS.map((option) => {

      return (
        <div className='radio'>
          <label>
            <input
              ref={option.ref}
              type='radio'
              name='permissions'
              checked={this.isPermissionChecked(option)}
              onChange={option.onChange.bind(this)}
            />
            {option.text}
          </label>
        </div>
      );
    });
  };

  RestrictedDialogForm.renderRestrictedAccessOptions = function () {
    if (this.state.selectedOption !== 'link_only' && this.state.selectedOption !== 'date_range') {
      return null;
    }

    return (
      <div style={{marginLeft: '20px'}}>
        {
          RestrictedDialogForm.RESTRICTED_OPTIONS.map((option) => {
            return (
              <div className='radio'>
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
  };

  RestrictedDialogForm.renderDatePickers = function () {

    var styleObj = {};
    if (this.state.selectedOption !== 'date_range') {
      styleObj.visibility = 'hidden';
    }

    return (
      <div className='control-group' style={styleObj}>
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
        <div className='control-group'>
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
  };

  // Renders out the restricted access form
  // - options is an object which can be used to conditionally set certain aspects
  //   of rendering.
  //   Future Refactor: Move this to another component should it's use elsewhere
  //                  be meritted.
  RestrictedDialogForm.renderRestrictedAccessForm = function (options) {
    var formContainerClasses = classNames({
      'RestrictedDialogForm__form': true,
      'col-xs-9': true,
      'off-xs-3': options && options.offset
    });

    return (
      <div className={formContainerClasses}>
        <form
          ref='dialogForm'
          onSubmit={this.handleSubmit}
          className='form-horizontal form-dialog permissions-dialog-form'
        >
        {this.renderPermissionOptions()}
        {this.renderRestrictedAccessOptions()}
        {this.renderDatePickers()}
          <div className='form-controls'>
            <button
              type='button'
              onClick={this.props.closeDialog}
              className='btn'
            >
              {I18n.t('Cancel')}
            </button>
            <button
              ref='updateBtn'
              type='submit'
              className='btn btn-primary'
              disabled={!this.state.selectedOption}
            >
              {I18n.t('Update')}
            </button>
          </div>
        </form>
      </div>
    );
  };

  RestrictedDialogForm.render = function () {
    // Doing this here to prevent possible repeat runs of this.usageRightsOnAll and this.allFolders
    var showUsageRights = this.props.usageRightsRequiredForContext && !this.usageRightsOnAll() && !this.allFolders();

    return (
      <div className='RestrictedDialogForm__container'>
        {/* If showUsageRights then show the Usage Rights Warning */}
        {!!showUsageRights && (
          <div className='RestrictedDialogForm__firstRow grid-row'>
            {this.renderUsageRightsWarning()}
          </div>
        )}
        <div className='RestrictedDialogForm__secondRow grid-row'>
          <div className='RestrictedDialogForm__preview col-xs-3'>
            <DialogPreview itemsToShow={this.props.models} />
          </div>
          {/* If showUsageRights then show the select box for it.*/}
          {!!showUsageRights && (
            <div className='RestrictedDialogForm__usageRights col-xs-9'>
              <UsageRightsSelectBox ref='usageSelection' />
              <hr />
            </div>
          )}
          {/* Not showing usage rights?, then show the form here.*/}
          {!showUsageRights && this.renderRestrictedAccessForm()}
        </div>
        {/* If showUsageRights,] it needs to be here instead */}
        {!!showUsageRights && (
          <div className='RestrictedDialogForm__thirdRow grid-row'>
            {this.renderRestrictedAccessForm({offset: true})}
          </div>
        )}
      </div>
    );
  };

  return React.createClass(RestrictedDialogForm);

});