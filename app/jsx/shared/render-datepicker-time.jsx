define(['i18n!instructure', 'timezone', 'react'], function(I18n, tz, React) {
  var STRINGS = {
    timeLabel: I18n.beforeLabel(I18n.t('Time')),
    hourTitle: I18n.t('datepicker.titles.hour', 'hr'),
    minuteTitle: I18n.t('datepicker.titles.minute', 'min'),
    selectTitle: I18n.t('datepicker.titles.am_pm', 'am/pm'),
    AM: I18n.t('#time.am'),
    PM: I18n.t('#time.pm'),
    doneButton: I18n.t('#buttons.done', 'Done')
  };

  return function($input) {
    var data = {
      hour:   ($input.data('time-hour')   || "").replace(/'/g, ""),
      minute: ($input.data('time-minute') || "").replace(/'/g, ""),
      ampm:   ($input.data('time-ampm')   || ""),
    };

    var label = (
      <label htmlFor='ui-datepicker-time-hour'>{STRINGS.timeLabel}</label>
    );

    var hourInput = (
      <input id='ui-datepicker-time-hour' type='text'
        defaultValue={data.hour} title={STRINGS.hourTitle}
        className='ui-datepicker-time-hour' style={{width: '20px'}} />
    );

    var minuteInput = (
      <input type='text'
        defaultValue={data.minute} title={STRINGS.minuteTitle}
        className='ui-datepicker-time-minute' style={{width: '20px'}} />
    );

    var meridianSelect = '';
    if (tz.useMeridian()) {
      // TODO: Change this select to work as described here:
      // http://facebook.github.io/react/docs/forms.html#why-select-value
      //
      // As of React 0.13.3 this issue: https://github.com/facebook/react/issues/1398
      // has not been fixed and released, which makes React.renderToStaticMarkup not
      // carry things through properly. So once that is done, we can fix the warning
      // here.
      meridianSelect = (
        <select className='ui-datepicker-time-ampm un-bootrstrapify' title={STRINGS.selectTitle}>
          <option value='' key='unset'>&nbsp;</option>
          <option value={STRINGS.AM} selected={data.ampm == 'am'} key='am'>{STRINGS.AM}</option>
          <option value={STRINGS.PM} selected={data.ampm == 'pm'} key='pm'>{STRINGS.PM}</option>
        </select>
      );
    }

    return React.renderToStaticMarkup(
      <div className='ui-datepicker-time ui-corner-bottom'>
        {label} {hourInput}:{minuteInput} {meridianSelect}
        <button type='button' className='btn btn-mini ui-datepicker-ok'>{STRINGS.doneButton}</button>
      </div>
    );
  };
});
