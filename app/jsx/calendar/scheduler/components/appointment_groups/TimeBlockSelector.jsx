define([
  'jquery',
  'react',
  'react-dom',
  'i18n!appointment_groups',
  'instructure-ui/Typography',
  'instructure-ui/Button',
  'instructure-ui/TextInput',
  './TimeBlockSelectRow',
  'compiled/util/coupleTimeFields',
  'compiled/calendar/TimeBlockListManager',
  'jquery.instructure_date_and_time'
], ($, React, ReactDOM, I18n, { default: Typography }, { default: Button }, { default: TextInput }, TimeBlockSelectRow, coupleTimeFields, TimeBlockListManager) => {
  class TimeBlockSelector extends React.Component {

    static propTypes = {
      className: React.PropTypes.string,
      timeData: React.PropTypes.arrayOf(React.PropTypes.object),
      onChange: React.PropTypes.func.isRequired
    };

    constructor (props) {
      super(props);
      this.newIdPrefix = 'NEW-';
      this.lastNewId = 0;
      this.state = {
        timeBlockRows: [{
          slotEventId: `${this.newIdPrefix}${this.lastNewId}`,
          timeData: {}
        }]
      };
      this.lastNewId++;
    }

    componentDidUpdate (prevProps, prevState) {
      if (prevState !== this.state) {
        this.props.onChange(this.state.timeBlockRows);
      }
    }

    getNewSlotData () {
      return this.state.timeBlockRows.map(tbr => ([
        tbr.timeData.startTime,
        tbr.timeData.endTime,
        false
      ]));
    }

    deleteRow = (slotEventId) => {
      const newRows = this.state.timeBlockRows.filter(e => e.slotEventId !== slotEventId);
      this.setState({
        timeBlockRows: newRows
      });
    }

    addRow = (timeData = {}) => {
      const newRows = [{
        slotEventId: `${this.newIdPrefix}${this.lastNewId}`,
        timeData
      }];
      this.setState({
        timeBlockRows: this.state.timeBlockRows.concat(newRows)
      }, () => this.lastNewId++);
    }

    addRowsFromBlocks = (timeBlocks) => {
      const newRows = timeBlocks.map(tb => ({
        slotEventId: `${this.newIdPrefix}${this.lastNewId++}`,
        timeData: tb
      }));
      // Make sure a new blank row is there as well.
      newRows.push({
        slotEventId: `${this.newIdPrefix}${this.lastNewId}`,
        timeData: {}
      });
      this.setState({
        timeBlockRows: newRows
      });
    }

    formatDate = (date) => {
      if (date.toDate) {
        return date.toDate();
      }
      return date;
    }

    handleSlotDivision = () => {
      const node = ReactDOM.findDOMNode(this);
      const minuteValue = $('.TimeBlockSelector__DivideSection-Input', node).val();
      const timeManager = new TimeBlockListManager(this.getNewSlotData());
      timeManager.split(minuteValue);
      const newBlocks = timeManager.blocks.map(block => ({
        date: this.formatDate(block.start),
        startTime: this.formatDate(block.start),
        endTime: this.formatDate(block.end)
      }));
      this.addRowsFromBlocks(newBlocks);
    }

    handleSetData = (timeslotId, data) => {
      const newRows = this.state.timeBlockRows.slice();
      const rowToUpdate = newRows.find(r => r.slotEventId === timeslotId);
      rowToUpdate.timeData = data;
      this.setState({
        timeBlockRows: newRows
      });
    }

    render () {
      const classes = (this.props.className) ? `TimeBlockSelector ${this.props.className}` :
                                               'TimeBlockSelector';
      return (
        <div className={classes}>
          {this.props.timeData.map(timeBlock => (
            <TimeBlockSelectRow {...timeBlock} key={timeBlock.slotEventId} readOnly />
          ))}
          {this.state.timeBlockRows.map(timeBlock => (
            <TimeBlockSelectRow
              key={timeBlock.slotEventId}
              handleDelete={this.deleteRow}
              onBlur={this.addRow}
              setData={this.handleSetData}
              {...timeBlock}
            />
          ))}
          <div className="TimeBlockSelector__DivideSection">
            <Typography>
              <label
                dangerouslySetInnerHTML={{
                  __html: I18n.t('Divide into equal slots of %{input_value} minutes. ', {
                    input_value: '<input class="TimeBlockSelector__DivideSection-Input" value="30" type="number"/>'
                  })
                }}
              />
              <Button
                size="small"
                onClick={this.handleSlotDivision}
              >{I18n.t('Create Slots')}</Button>
            </Typography>
          </div>
        </div>
      );
    }
  }

  return TimeBlockSelector;
});
