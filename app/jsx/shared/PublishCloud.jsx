define([
  'jquery',
  'react',
  'i18n!publish_cloud',
  'compiled/react_files/components/PublishCloud',
  'compiled/react_files/components/RestrictedDialogForm'
], function ($, React, I18n, PublishCloud, RestrictedDialogForm) {

  // Function Summary
  // Create a blank dialog window via jQuery, then dump the RestrictedDialogForm into that
  // dialog window. This allows us to do react things inside of this all ready rendered
  // jQueryUI widget
  PublishCloud.openRestrictedDialog = function () {
    var $dialog = $('<div>').dialog({
      title: I18n.t('Editing permissions for: %{name}', {name: this.props.model.displayName()}),
      width: 800,
      minHeight: 300,
      close: function () {
        React.unmountComponentAtNode(this);
        $(this).remove();
      }
    });

    React.render(RestrictedDialogForm({
      usageRightsRequiredForContext: this.props.usageRightsRequiredForContext,
      models: [this.props.model],
      closeDialog: function () { $dialog.dialog('close'); }
    }), $dialog[0]);

  };

  PublishCloud.render = function () {
    if (this.props.userCanManageFilesForContext) {
      if (this.state.published && this.state.restricted) {
        return (
          <button
            type='button'
            data-tooltip='left'
            onClick={this.openRestrictedDialog}
            ref='publishCloud'
            className='btn-link published-status restricted'
            title={this.getRestrictedText()}
            aria-label={this.getRestrictedText() + ' - ' + I18n.t('Click to modify')}
          >
            <i className='icon-cloud-lock' />
          </button>
        );
      } else if (this.state.published && this.state.hidden) {
        return (
          <button
            type='button'
            data-tooltip='left'
            onClick={this.openRestrictedDialog}
            ref='publishCloud'
            className='btn-link published-status hiddenState'
            title={I18n.t('Hidden. Available with a link')}
            aria-label={I18n.t('Hidden. Available with a link - Click to modify')}
          >
            <i className='icon-cloud-lock' />
          </button>
        );
      } else if (this.state.published) {
        return (
          <button
            type='button'
            data-tooltip='left'
            onClick={this.openRestrictedDialog}
            ref='publishCloud'
            className='btn-link published-status published'
            title={I18n.t('Published')}
            aria-label={I18n.t('Published - Click to modify')}
          >
            <i className='icon-publish' />
          </button>
        );
      } else {
        return (
          <button
            type='button'
            data-tooltip='left'
            onClick={this.openRestrictedDialog}
            ref='publishCloud'
            className='btn-link published-status unpublished'
            title={I18n.t('Unpublished')}
            aria-label={I18n.t('Unpublished - Click to modify')}
          >
            <i className='icon-unpublish' />
          </button>
        );
      }
    } else {
      if (this.state.published && this.state.restricted) {
        return (
          <div
            style={{marginRight: '12px'}}
            data-tooltip='left'
            ref='publishCloud'
            className='published-status restricted'
            title={this.getRestrictedText()}
            aria-label={this.getRestrictedText()}
          >
            <i className='icon-calendar-day' />
          </div>
        );
      } else {
        return (
          <div style={{width: 28, height: 36}} />
        );
      }
    }

  };

  return React.createClass(PublishCloud);

});
