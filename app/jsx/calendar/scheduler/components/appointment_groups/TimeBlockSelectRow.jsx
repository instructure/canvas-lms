define([
  'jquery',
  'react',
  'i18n!appointment_groups',
  'instructure-ui/Button',
  'instructure-ui/ScreenReaderContent',
  'compiled/util/coupleTimeFields',
  'jquery.instructure_date_and_time'
], ($, React, I18n, { default: Button }, { default: ScreenReaderContent }, coupleTimeFields) => {
  const dateToString = (dateObj, format) => {
    if (!dateObj) {
      return '';
    }
    return I18n.l(`date.formats.${format}`, $.fudgeDateForProfileTimezone(dateObj));
  };

  const timeToString = (dateObj, format) => {
    if (!dateObj) {
      return '';
    }
    return I18n.l(`time.formats.${format}`, $.fudgeDateForProfileTimezone(dateObj));
  };

  class TimeBlockSelectorRow extends React.Component {

    static propTypes = {
      timeData: React.PropTypes.shape({
        date: React.PropTypes.date,
        startTime: React.PropTypes.date,
        endTime: React.PropTypes.date
      }).isRequired,
      slotEventId: React.PropTypes.string,
      readOnly: React.PropTypes.bool,
      onBlur: React.PropTypes.func.isRequired,
      handleDelete: React.PropTypes.func.isRequired,
      setData: React.PropTypes.func.isRequired
    };

    constructor (props) {
      super(props);
      this.state = {};
    }

    componentDidMount () {
      const options = {};
      if (this.props.readOnly) {
        options.disableButton = true;
      }
      $(this.date).date_field(options);
      $(this.startTime).time_field();
      $(this.endTime).time_field();
      coupleTimeFields($(this.startTime), $(this.endTime), $(this.date));
    }

    prepareData = () => {
      const data = {
        date: $(this.date).data('date'),
        startTime: $(this.startTime).data('date'),
        endTime: $(this.endTime).data('date')
      };

      this.props.setData(this.props.slotEventId, data);
    }

    handleDelete = (e) => {
      e.preventDefault();
      this.props.handleDelete(this.props.slotEventId);
    }

    handleFieldBlur = (e) => {
      // In some browsers, we actually need to handle the update of data on blur
      this.prepareData();
      // Only call the onBlur if it's non blank, and it's not the last one in the list.
      if (!$(e.target).data('blank') && $(e.target).closest('.TimeBlockSelectorRow').is(':last-child')) {
        this.props.onBlur();
      }
    }

    render () {
      return (
        <div className="TimeBlockSelectorRow grid-row start-xs">
          <div className="col-xs">
            <input
              type="text"
              disabled={this.props.readOnly}
              aria-disabled={this.props.readOnly ? 'true' : null}
              ref={(c) => { this.date = c; }}
              className="TimeBlockSelectorRow__Date"
              onChange={this.prepareData}
              onBlur={this.handleFieldBlur}
              placeholder={I18n.t('Date')}
              defaultValue={dateToString(this.props.timeData.date, 'medium')}
            />
          </div>
          <div className="col-xs">
            <input
              type="text"
              disabled={this.props.readOnly}
              aria-disabled={this.props.readOnly ? 'true' : null}
              ref={(c) => { this.startTime = c; }}
              className="TimeBlockSelectorRow__StartTime"
              onChange={this.prepareData}
              onBlur={this.handleFieldBlur}
              placeholder={I18n.t('Start Time')}
              defaultValue={timeToString(this.props.timeData.startTime, 'tiny')}
            />
          </div>
          <div className="col-xs">
            <span className="TimeBlockSelectorRow__TimeSeparator">{I18n.t('to')}</span>
          </div>
          <div className="col-xs">
            <input
              type="text"
              disabled={this.props.readOnly}
              aria-disabled={this.props.readOnly ? 'true' : null}
              ref={(c) => { this.endTime = c; }}
              className="TimeBlockSelectorRow__EndTime"
              onChange={this.prepareData}
              onBlur={this.handleFieldBlur}
              placeholder={I18n.t('End Time')}
              defaultValue={timeToString(this.props.timeData.endTime, 'tiny')}
            />
          </div>
          <div className="col-xs">
            {
              !this.props.readOnly && (
                <Button ref={(c) => { this.deleteBtn = c; }} variant="icon" onClick={this.handleDelete}>
                  <i className="icon-end">
                    <ScreenReaderContent>{I18n.t('Delete Time Range')}</ScreenReaderContent>
                  </i>
                </Button>
              )
            }
          </div>
        </div>
      );
    }
  }

  return TimeBlockSelectorRow;
});
