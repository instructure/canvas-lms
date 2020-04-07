import React from 'react'
import styled from 'styled-components'

const Card = styled.div`
  box-sizing: border-box;
  border-radius: 4px;
  background: #f5f5f6;
  color: #212329;
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  overflow-y: scroll;

  .course-title {
    padding: 0.5rem;
    display: flex;
    align-items: center;
    justify-content: flex-start;
    border-bottom: 5px solid ${props => props.course_color};

    h4 {
      font-weight: bold;
      font-size: 18px;
      flex-grow: 1;
      padding: 0 0.5rem;
      width: 100%;
    }

    i {
      &:before {
        color: #212329;
        font-size: 14px;
      }
    }
  }

  p {
    text-align: center;
  }

  span {
    font-size: 12px;
    
    &.title {
      font-weight: bold;
    }
  }

  .course-info {
    display: flex;
    flex-direction: column;

    .gradebook-link {
      color: #006ba6;
      font-family: "Open Sans", sans-serif;
      font-size: 12px;
      margin-top: auto;
      padding: 1rem 0;
      text-decoration: underline;
    }
  }

  .missing-assignments {
    background: ${props => props.assignment_color};
    border-radius: 25px;
    color: #ffffff;
    font-weight: bold;
    padding: 0.2rem 0.5rem;

    span {
      font-size: 11px;
    }
  }

  .course-teachers {
    color: #696969;
    font-style: italic;
  }

  .course-score {
    font-family: "Montserrat", sans-serif; 
    font-size: 30px;
    font-weight: bold;
    color: #006ba6;
  }

  .flex-widgets {
    display: flex;
    flex-flow: row wrap;
    justify-content: flex-start;
    margin: -0.5rem 0.5rem;

    > * {
      flex-basis: 50%;
      width: 100%;
      padding: 0.5rem;
      box-sizing: border-box;
      position: relative;

      > * {
        background: #f2fdfd;
        border: 1px solid #4FBBC1;
        border-radius: 4px;
        color: #212329;
        height: 100%;
        margin: 0;

        > * {
          line-height: 1em;
          padding: 0.75rem;
        }
  
        .title {
          background: #4FBBC1;
          color: #ffffff;
          padding: 0.5rem;
        }
      }
    }
  }

  .submission-date, .last-active {
    span {
      display: block;
    }
  }

  &.animate-card {
		animation: card-slide 0.7s 1;
  }

  @keyframes card-slide {
    0% {
      transform: translateX(100%);
      z-index: 2;
    }

    100% {
      transform: translateX(0);
    }
  }
`

class ObserveeCourseDetails extends React.Component {
  constructor(props) {
    super(props);
  }

  static defaultProps = {
    enrollment: {},
    color: "",
    score: "",
    course_details: {},
    is_showing: false,
  };

  missingAssignmentColor(missing, total) {
    let num = missing / total;
  
    // yellow: less than 5% of total assignments missing
    if (num <= 0.05) {
      return '#EBB64C'
    }

    // orange: between 5% and 10% of total assignments missing
    if (num > 0.05 && num <= 0.1) {
      return '#EB814C'
    }

    // red: more than 10% of total assignments missing
    if (num > 0.1 ) {
      return '#EB4C4C'
    }
  }

  determineLastActive(days) {
    if (days === 'N/A') {
      return 'Never';
    } else if (days == 0) {
      return 'Today';
    } 
    return days + ' days ago';
  }

  renderMissingAssignments(num) {
    // only render this element if there are missing assignments
    if (num > 0) {
      return <div><span className="missing-assignments">{this.props.course_details.missing_assignments} missing assignments</span></div>;
    }
  }

  render() {
    return (
      <Card course_color={this.props.color} className={this.props.is_showing ? 'animate-card' : ''} assignment_color={this.missingAssignmentColor(this.props.course_details.missing_assignments, this.props.course_details.total_assignment_count)}>
        <section className="course-title">
          <a className="back-button" href="#" onClick={this.props.reset_action}>
            <i className="icon-arrow-open-left"></i>
          </a>
          <h4>{this.props.enrollment.course_name}</h4>
        </section>
        <section className="course-info">
          <p className="course-teachers">
            <span className="title">Teachers: </span>
            {this.props.course_details.teachers.join(', ')}
          </p>
          { this.renderMissingAssignments(this.props.course_details.missing_assignments) }
          <p className="course-score">{this.props.score}</p>
          <div className="flex-widgets">
            <div>
              <p className="submission-date">
                <span className="title">Last submission:</span>
                <span>{this.props.course_details.last_submission}</span>
              </p>
            </div>
            <div>
              <p className="last-active">
                <span className="title">Last active:</span>
                <span>{this.determineLastActive(this.props.course_details.last_active)}</span>
              </p>
            </div>
          </div>
          <a className="gradebook-link"
            href={`/courses/${this.props.enrollment.course_id}/grades`}
            title={`${this.props.enrollment.course_name} grades`}>
              View Grades
          </a>
        </section>
      </Card>
    )
  }
}

export default ObserveeCourseDetails