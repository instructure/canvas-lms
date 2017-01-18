define([
  'react',
  'i18n!react_files',
  'compiled/react_files/components/FilesUsage',
  'compiled/util/friendlyBytes',
], (React, I18n, FilesUsage, friendlyBytes) => {

  FilesUsage.render = function () {
    if (this.state) {
      const percentUsed = Math.round(this.state.quota_used / this.state.quota * 100);
      const label = I18n.t('%{percentUsed} of %{bytesAvailable} used', {
        percentUsed: I18n.n(percentUsed, { percentage: true }),
        bytesAvailable: friendlyBytes(this.state.quota)
      });
      const srLabel = I18n.t('Files Quota: %{percentUsed} of %{bytesAvailable} used', {
        percentUsed: I18n.n(percentUsed, { percentage: true }),
        bytesAvailable: friendlyBytes(this.state.quota)
      });
      return (
        <div className='grid-row ef-quota-usage'>
          <div className='col-xs-5'>
            <div ref='container' className='progress-bar__bar-container' aria-hidden={true}>
              <div
                ref='bar'
                className='progress-bar__bar'
                style={{
                  width: Math.min(percentUsed, 100) + '%'
                }}
              />
            </div>
          </div>
          <div className='col-xs-7' style={{paddingLeft: '0px'}} aria-hidden={true}>
            {label}
          </div>
          <div className='screenreader-only'>{srLabel}</div>
        </div>
      );
    } else {
      return <div />;
    }
  };

  return React.createClass(FilesUsage);
});
