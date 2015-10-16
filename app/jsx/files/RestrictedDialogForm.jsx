define([
  'underscore',
  'react',
  'i18n!restrict_student_access',
  'jquery',
  'classnames',
  'jsx/files/UsageRightsSelectBox',
  'jsx/files/RestrictedRadioButtons',
  'jsx/files/DialogPreview',
  'compiled/react_files/components/RestrictedDialogForm'
], function (_, React, I18n, $, classNames, UsageRightsSelectBox, RestrictedRadioButtons, DialogPreview, RestrictedDialogForm) {

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
        <RestrictedRadioButtons
          ref='restrictedSelection'
          models={this.props.models}
          radioStateChange={this.radioStateChange}
        >
        </RestrictedRadioButtons>
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
              disabled={!this.state.submitable}
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
