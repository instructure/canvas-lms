import React from 'react';
import styled from 'styled-components';
import moment from 'moment';
import axios from 'axios';
import { flashError } from 'jquery';
import { flashMessage } from 'jquery';

const Card = styled.div`
  border: 1px solid #D7D7D7;
  border-radius: 4px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.3);
  text-align: center;
  height: 100%;
  width: 100%;
  max-width: 1000px;
  margin: 0 auto;
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-direction: column;

  .title, .section {
    text-align: center;
  }

  .course-date-fields {
    display: flex;
  }

  .course-date-row {
    display: flex;
    flex-direction: column;
    padding: 1rem;
  }

  .due-date-btn {
    margin: .5rem .25rem;
  }

  .course-date-title {
    font-weight: 600;
  }

  .warning {
    color: red;
  }
`

class DueDateWizard extends React.Component {
  constructor(props) {
    super(props);
  }
  
  static defaultProps = {
    course: {},
  };

  componentDidMount() {
    console.log(this.props.course);
  }

  formatDateString(dateStr) {
    let date = dateStr === "start" ? this.props.course.start_at : this.props.course.conclude_at;
    return moment(date).format("MM-DD-YY");
  }

  innerCard() {
    let course = this.props.course;
    let component;

    if (course.start_at && course.conclude_at) {
      component = this.datePusher();
    } else {
      component = this.noDateWarning();
    }

    return (
      <section className="section">
        {component}
      </section>
    );
  }

  noDateWarning() {
    return (
      <div>
        <h2 className="warning">PLEASE ADD START AND END DATES TO YOUR COURSE</h2>
      </div>
    );
  }

  datePusher() {
    return (
      <div>
        <div className="course-date-fields">
          <div className="course-date-row">
            <span className="course-date-title">
              Course Start Date:
            </span>
            <span>
              {this.formatDateString('start')}
            </span>
          </div>

          <div className="course-date-row">
            <span className="course-date-title">
              Course End Date:
            </span>
            <span>
              {this.formatDateString('end')}
            </span>
          </div>
        </div>
      </div>
    );
  }

  confirmDistribute() {
    return confirm(`You are about to distribute due dates between ${this.formatDateString('start')} \
      and ${this.formatDateString('end')}. Please confirm you want to complete this action.
    `.replace(/  +/g, ' '));
  }
  
  distributeDueDates() {
    if (this.confirmDistribute()) {
      axios.post(`/courses/${this.props.course.id}/distribute_due_dates`).then(() => {
        flashMessage('Dates are distributing');
      });
    }
  }

  confirmClear() {
    return confirm(`You are about to clear all due dates from this course. \
      Course assignments will no longer have due dates or calendar events. \
      Please confirm that you want to complete this action.`.replace(/  +/g, ' '));
  }

  clearDueDates() {
    if (this.confirmClear()) {
      axios.post(`/courses/${this.props.course.id}/clear_due_dates`).then(() => {
        flashMessage("Due dates are clearing");
      });
    }
  }
  
  renderButtons() {
    return (
      <div>
        <button className="sm-btn-primary due-date-btn" onClick={this.distributeDueDates.bind(this)}>Distribute Due Dates</button>
        <button className="sm-btn-secondary due-date-btn" onClick={this.clearDueDates.bind(this)}>Clear Due Dates</button>
      </div>
    )
  }

  render() {
    return (
      <Card>
        <h3 className="title">Distribute Dates for Course '{this.props.course.name}'</h3>
        {this.innerCard()}
        {this.renderButtons()}
      </Card>
    )
  }
}

export default DueDateWizard;