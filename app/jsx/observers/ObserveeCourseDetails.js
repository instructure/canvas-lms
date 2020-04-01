import React from 'react'
import styled from 'styled-components'

const Card = styled.div`
  box-sizing: border-box;
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
      padding: 0.5rem 0;
      text-decoration: underline;
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

  render() {
    return (
      <Card course_color={this.props.color} className={this.props.is_showing ? 'animate-card' : ''}>
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
          <p className="course-score">{this.props.score}</p>
          <p className="submission-date">
            <span className="title">Date of last submission:</span>
            <span>{this.props.course_details.last_submission}</span>
          </p>
          <p className="last-active">
            <span className="title">Days since last active:</span>
            <span>{this.props.course_details.last_active}</span>
          </p>
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