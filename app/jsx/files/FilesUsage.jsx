define([
  'react',
  'i18n!react_files',
  'compiled/react_files/components/FilesUsage',
  'compiled/util/friendlyBytes',
  'jsx/shared/ProgressBar'
], function (React, I18n, FilesUsage, friendlyBytes, ProgressBar) {

  FilesUsage.render = function () {
    if (this.state) {
      var percentUsed = Math.round(this.state.quota_used / this.state.quota * 100);
      var label = I18n.t('%{percentUsed}% of %{bytesAvailable} used', {
        percentUsed: percentUsed,
        bytesAvailable: friendlyBytes(this.state.quota)
      });
      return (
        <div className='grid-row ef-quota-usage'>
          <div className='col-xs-5'>
            <ProgressBar progress={percentUsed} aria-label={label} />
          </div>
          <div className='col-xs-7' style={{paddingLeft: '0px'}} aria-hidden={true}>
            {label}
          </div>
        </div>
      );
    } else {
      return <div />;
    }
  };

  return React.createClass(FilesUsage);

});
