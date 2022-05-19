/*
 * Copyright (C) 2018 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import Header from '../Header'
import {mockAssignmentAndSubmission, mockSubmission} from '@canvas/assignments/graphql/studentMocks'
import React from 'react'
import {fireEvent, render} from '@testing-library/react'
import StudentViewContext from '../Context'
import {SubmissionMocks} from '@canvas/assignments/graphql/student/Submission'

jest.mock('../AttemptSelect')
jest.mock('../CommentsTray', () => () => '')

it('renders normally', async () => {
  const props = await mockAssignmentAndSubmission()
  const {getByTestId} = render(<Header {...props} />)
  expect(getByTestId('assignment-student-header')).toBeInTheDocument()
})

it('renders a "late" status pill if the last graded submission is late', async () => {
  const props = await mockAssignmentAndSubmission({
    Assignment: {
      gradingType: 'points',
      pointsPossible: 10
    },
    Submission: {
      ...SubmissionMocks.graded,
      attempt: 1,
      deductedPoints: 4,
      enteredGrade: 10,
      grade: 6,
      submissionStatus: 'late'
    }
  })
  const {getByText} = render(
    <StudentViewContext.Provider value={{lastSubmittedSubmission: props.submission}}>
      <Header {...props} />
    </StudentViewContext.Provider>
  )
  expect(getByText('Late')).toBeInTheDocument()
})

it('shows the grade for a late submission if it is not hidden from the student', async () => {
  const props = await mockAssignmentAndSubmission({
    Assignment: {
      gradingType: 'points',
      pointsPossible: 10
    },
    Submission: {
      ...SubmissionMocks.graded,
      attempt: 1,
      deductedPoints: 4,
      enteredGrade: 10,
      grade: 6,
      gradeHidden: false,
      submissionStatus: 'late'
    }
  })
  const {getByText} = render(
    <StudentViewContext.Provider value={{lastSubmittedSubmission: props.submission}}>
      <Header {...props} />
    </StudentViewContext.Provider>
  )
  expect(getByText('6/10 Points')).toBeInTheDocument()
})

it('shows N/A for a late submission if the grade is hidden from the student', async () => {
  const props = await mockAssignmentAndSubmission({
    Assignment: {
      gradingType: 'points',
      pointsPossible: 10
    },
    Submission: {
      ...SubmissionMocks.submitted,
      attempt: 1,
      gradeHidden: true,
      submissionStatus: 'late'
    }
  })
  const {getByTestId} = render(
    <StudentViewContext.Provider value={{lastSubmittedSubmission: props.submission}}>
      <Header {...props} />
    </StudentViewContext.Provider>
  )
  expect(getByTestId('assignment-student-header')).toHaveTextContent(/Attempt 1 Score:\s*N\/A/)
})

it('shows the number of points deducted in the tooltip when the current grade is focused', async () => {
  const props = await mockAssignmentAndSubmission({
    Assignment: {
      gradingType: 'points',
      pointsPossible: 10
    },
    Submission: {
      ...SubmissionMocks.graded,
      attempt: 1,
      deductedPoints: 4,
      enteredGrade: 10,
      grade: 6,
      submissionStatus: 'late'
    }
  })

  const {getByText} = render(
    <StudentViewContext.Provider value={{lastSubmittedSubmission: props.submission}}>
      <Header {...props} />
    </StudentViewContext.Provider>
  )
  const pointsDisplay = getByText('6/10 Points')
  fireEvent.focus(pointsDisplay)
  expect(getByText('Late Penalty')).toBeInTheDocument()
  expect(getByText('-4')).toBeInTheDocument()
})

it('renders a "missing" status pill if the last graded submission is missing', async () => {
  const props = await mockAssignmentAndSubmission({
    Submission: {
      ...SubmissionMocks.graded,
      submissionStatus: 'missing'
    }
  })
  const {getByText} = render(
    <StudentViewContext.Provider value={{lastSubmittedSubmission: props.submission}}>
      <Header {...props} />
    </StudentViewContext.Provider>
  )
  expect(getByText('Missing')).toBeInTheDocument()
})

it('does not render a status pill if the last graded submission is not late or missing', async () => {
  const props = await mockAssignmentAndSubmission({
    Submission: SubmissionMocks.graded
  })
  const {queryByText} = render(
    <StudentViewContext.Provider value={{lastSubmittedSubmission: props.submission}}>
      <Header {...props} />
    </StudentViewContext.Provider>
  )
  expect(queryByText('Late')).not.toBeInTheDocument()
  expect(queryByText('Missing')).not.toBeInTheDocument()
})

it('shows the most recently received grade as the "canonical" score', async () => {
  const lastSubmittedSubmission = await mockSubmission({
    Submission: {
      ...SubmissionMocks.graded,
      grade: '147',
      enteredGrade: '147'
    }
  })

  const props = await mockAssignmentAndSubmission({
    Assignment: {pointsPossible: 150},
    Submission: {
      ...SubmissionMocks.graded,
      grade: '131',
      enteredGrade: '131'
    }
  })

  const {getByText} = render(
    <StudentViewContext.Provider value={{lastSubmittedSubmission}}>
      <Header {...props} />
    </StudentViewContext.Provider>
  )

  expect(getByText('147/150 Points')).toBeInTheDocument()
})

it('renders the grade for the currently selected attempt', async () => {
  const lastSubmittedSubmission = await mockSubmission({
    Submission: {
      ...SubmissionMocks.graded,
      grade: '147',
      enteredGrade: '147'
    }
  })

  const props = await mockAssignmentAndSubmission({
    Assignment: {pointsPossible: 150},
    Submission: {
      ...SubmissionMocks.graded,
      attempt: 7,
      grade: '131',
      enteredGrade: '131',
      gradingStatus: 'graded'
    }
  })

  const {container} = render(
    <StudentViewContext.Provider value={{lastSubmittedSubmission}}>
      <Header {...props} />
    </StudentViewContext.Provider>
  )

  expect(container).toHaveTextContent(/Attempt 7 Score:\s*131\/150/)
})

it('renders "N/A" for the currently selected attempt if it has no grade', async () => {
  const lastSubmittedSubmission = await mockSubmission({
    Submission: {
      ...SubmissionMocks.graded,
      grade: '147',
      enteredGrade: '147'
    }
  })

  const props = await mockAssignmentAndSubmission({
    Assignment: {pointsPossible: 150},
    Submission: {
      ...SubmissionMocks.submitted,
      attempt: 7,
      grade: '131',
      enteredGrade: '131',
      gradingStatus: 'needs_grading'
    }
  })

  const {container} = render(
    <StudentViewContext.Provider value={{lastSubmittedSubmission}}>
      <Header {...props} />
    </StudentViewContext.Provider>
  )

  expect(container).toHaveTextContent(/Attempt 7 Score:\s*N\/A/)
})

it('renders "Offline Score" when the student is graded before submitting', async () => {
  const lastSubmittedSubmission = await mockSubmission({
    Submission: {
      ...SubmissionMocks.graded,
      grade: '147',
      enteredGrade: '147',
      attempt: 0
    }
  })

  const props = await mockAssignmentAndSubmission({
    Assignment: {pointsPossible: 150},
    Submission: {
      ...SubmissionMocks.graded,
      attempt: 0,
      grade: '131',
      enteredGrade: '131'
    }
  })

  const {container} = render(
    <StudentViewContext.Provider value={{lastSubmittedSubmission}}>
      <Header {...props} />
    </StudentViewContext.Provider>
  )

  expect(container).toHaveTextContent(/Offline Score:\s*131\/150/)
})

it('will not render the grade if the last submitted submission is excused', async () => {
  const lastSubmittedSubmission = await mockSubmission({
    Submission: {
      ...SubmissionMocks.excused,
      grade: '147',
      enteredGrade: '147'
    }
  })

  const props = await mockAssignmentAndSubmission({
    Assignment: {pointsPossible: 150},
    Submission: {
      ...SubmissionMocks.graded,
      grade: '131',
      enteredGrade: '131'
    }
  })

  const {getByTestId} = render(
    <StudentViewContext.Provider value={{lastSubmittedSubmission}}>
      <Header {...props} />
    </StudentViewContext.Provider>
  )

  expect(getByTestId('grade-display').textContent).toEqual('Excused')
})

it('renders the attempt select', async () => {
  const props = await mockAssignmentAndSubmission({
    Submission: {...SubmissionMocks.submitted}
  })
  props.allSubmissions = [props.submission]
  const {queryByTestId} = render(<Header {...props} />)
  expect(queryByTestId('attemptSelect')).toBeInTheDocument()
})

it('does not render the attempt select if there is no submission', async () => {
  const props = await mockAssignmentAndSubmission({Submission: null})
  props.allSubmissions = [{id: '1', _id: '1'}]
  const {queryByTestId} = render(<Header {...props} />)
  expect(queryByTestId('attemptSelect')).not.toBeInTheDocument()
})

it('does not render the attempt select if allSubmissions is not provided', async () => {
  const props = await mockAssignmentAndSubmission({
    Submission: {...SubmissionMocks.submitted}
  })
  const {queryByTestId} = render(<Header {...props} />)
  expect(queryByTestId('attemptSelect')).not.toBeInTheDocument()
})

it('does not render the attempt select if the assignment has non-digital submissions', async () => {
  const props = await mockAssignmentAndSubmission({
    Assignment: {nonDigitalSubmission: true},
    Submission: {...SubmissionMocks.submitted}
  })
  const {queryByTestId} = render(<Header {...props} />)
  expect(queryByTestId('attemptSelect')).not.toBeInTheDocument()
})

it('does not render the attempt select if peerReviewModeEnabled is set to true', async () => {
  const props = await mockAssignmentAndSubmission({
    Submission: {...SubmissionMocks.submitted}
  })
  props.assignment.env.peerReviewModeEnabled = true
  props.allSubmissions = [props.submission]
  const {queryByTestId} = render(<Header {...props} />)
  expect(queryByTestId('attemptSelect')).not.toBeInTheDocument()
})

it('renders the attempt select if peerReviewModeEnabled is set to false', async () => {
  const props = await mockAssignmentAndSubmission({
    Submission: {...SubmissionMocks.submitted}
  })
  props.assignment.env.peerReviewModeEnabled = false
  props.allSubmissions = [props.submission]
  const {queryByTestId} = render(<Header {...props} />)
  expect(queryByTestId('attemptSelect')).toBeInTheDocument()
})

describe('submission workflow tracker', () => {
  it('is rendered when a submission exists and the assignment is available', async () => {
    const props = await mockAssignmentAndSubmission()
    const {queryByTestId} = render(<Header {...props} />)
    expect(queryByTestId('submission-workflow-tracker')).toBeInTheDocument()
  })

  it('is not rendered when no submission object is present', async () => {
    const props = await mockAssignmentAndSubmission({Submission: null})
    props.allSubmissions = [{id: '1', _id: '1'}]
    const {queryByTestId} = render(<Header {...props} />)
    expect(queryByTestId('submission-workflow-tracker')).not.toBeInTheDocument()
  })

  it('is not rendered when there is no current user', async () => {
    const props = await mockAssignmentAndSubmission()
    props.assignment.env.currentUser = null
    const {queryByTestId} = render(<Header {...props} />)
    expect(queryByTestId('submission-workflow-tracker')).not.toBeInTheDocument()
  })

  it('is not rendered when the assignment has not been unlocked yet', async () => {
    const props = await mockAssignmentAndSubmission()
    props.assignment.env.modulePrereq = 'simulate not null'
    const {queryByTestId} = render(<Header {...props} />)
    expect(queryByTestId('submission-workflow-tracker')).not.toBeInTheDocument()
  })

  it('is not rendered when the assignment has uncompleted prerequisites', async () => {
    const props = await mockAssignmentAndSubmission()
    props.assignment.env.unlockDate = 'soon'
    const {queryByTestId} = render(<Header {...props} />)
    expect(queryByTestId('submission-workflow-tracker')).not.toBeInTheDocument()
  })

  it('is rendered if peerReviewModeEnabled is set to false', async () => {
    const props = await mockAssignmentAndSubmission()
    props.assignment.env.peerReviewModeEnabled = false
    const {queryByTestId} = render(<Header {...props} />)
    expect(queryByTestId('submission-workflow-tracker')).toBeInTheDocument()
  })

  it('is not rendered if peerReviewModeEnabled is set to true', async () => {
    const props = await mockAssignmentAndSubmission()
    props.assignment.env.peerReviewModeEnabled = true
    const {queryByTestId} = render(<Header {...props} />)
    expect(queryByTestId('submission-workflow-tracker')).not.toBeInTheDocument()
  })
})

describe('originality report', () => {
  it('is rendered when a submission exists with turnitinData attached and the assignment is available with a text entry submission', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: {submissionType: 'online_text_entry'}
    })
    props.submission.turnitinData = [
      {
        similarity_score: 10,
        state: 'acceptable',
        report_url: 'http://example.com',
        status: 'scored',
        data: '{}'
      }
    ]
    const {queryByTestId} = render(<Header {...props} />)
    expect(queryByTestId('originality_report')).toBeInTheDocument()
  })

  it('is rendered when a submission exists with turnitinData attached and the assignment is available with a online upload submission with only one attachment', async () => {
    const file = {
      _id: '1',
      displayName: 'file_1.png',
      id: '1',
      mimeClass: 'image',
      submissionPreviewUrl: '/preview_url',
      thumbnailUrl: '/thumbnail_url',
      url: '/url'
    }
    const props = await mockAssignmentAndSubmission({
      Submission: {submissionType: 'online_upload', attachments: [file]}
    })
    props.submission.turnitinData = [
      {
        similarity_score: 10,
        state: 'acceptable',
        report_url: 'http://example.com',
        status: 'scored',
        data: '{}'
      }
    ]
    const {queryByTestId} = render(<Header {...props} />)
    expect(queryByTestId('originality_report')).toBeInTheDocument()
  })

  it('is not rendered when a submission exists with turnitinData attached and the assignment is available with a online upload submission with more than one attachment', async () => {
    const files = [
      {
        _id: '1',
        displayName: 'file_1.png',
        id: '1',
        mimeClass: 'image',
        submissionPreviewUrl: '/preview_url',
        thumbnailUrl: '/thumbnail_url',
        url: '/url'
      },
      {
        _id: '1',
        displayName: 'file_1.png',
        id: '1',
        mimeClass: 'image',
        submissionPreviewUrl: '/preview_url',
        thumbnailUrl: '/thumbnail_url',
        url: '/url'
      }
    ]
    const props = await mockAssignmentAndSubmission({
      Submission: {submissionType: 'online_upload', attachments: files}
    })
    props.submission.turnitinData = [
      {
        similarity_score: 10,
        state: 'acceptable',
        report_url: 'http://example.com',
        status: 'scored',
        data: '{}'
      },
      {
        similarity_score: 10,
        state: 'acceptable',
        report_url: 'http://example.com',
        status: 'scored',
        data: '{}'
      }
    ]
    const {queryByTestId} = render(<Header {...props} />)
    expect(queryByTestId('originality_report')).not.toBeInTheDocument()
  })

  it('is not rendered when no submission object is present', async () => {
    const props = await mockAssignmentAndSubmission({Submission: null})
    props.allSubmissions = [{id: '1', _id: '1'}]
    const {queryByTestId} = render(<Header {...props} />)
    expect(queryByTestId('originality_report')).not.toBeInTheDocument()
  })

  it('is not rendered when there is no current user', async () => {
    const props = await mockAssignmentAndSubmission()
    props.assignment.env.currentUser = null
    const {queryByTestId} = render(<Header {...props} />)
    expect(queryByTestId('originality_report')).not.toBeInTheDocument()
  })

  it('is not rendered when the assignment has not been unlocked yet', async () => {
    const props = await mockAssignmentAndSubmission()
    props.assignment.env.modulePrereq = 'simulate not null'
    const {queryByTestId} = render(<Header {...props} />)
    expect(queryByTestId('originality_report')).not.toBeInTheDocument()
  })

  it('is not rendered when the assignment has uncompleted prerequisites', async () => {
    const props = await mockAssignmentAndSubmission()
    props.assignment.env.unlockDate = 'soon'
    const {queryByTestId} = render(<Header {...props} />)
    expect(queryByTestId('originality_report')).not.toBeInTheDocument()
  })

  it('is not rendered when the submission has no turnitinData', async () => {
    const props = await mockAssignmentAndSubmission()
    props.submission.turnitinData = null
    props.assignment.env.unlockDate = 'soon'
    const {queryByTestId} = render(<Header {...props} />)
    expect(queryByTestId('originality_report')).not.toBeInTheDocument()
  })
})

describe('Add Comment/View Feedback button', () => {
  it('renders as "Add Comment" by default', async () => {
    const props = await mockAssignmentAndSubmission()
    const {getByText} = render(<Header {...props} />)
    expect(getByText('Add Comment')).toBeInTheDocument()
  })

  it('shows the unread comments badge if there are unread comments', async () => {
    const props = await mockAssignmentAndSubmission({Submission: {unreadCommentCount: 1}})
    const {getByTestId} = render(<Header {...props} />)
    expect(getByTestId('unread_comments_badge')).toBeInTheDocument()
  })

  it('does not show the unread comments badge if there are no unread comments', async () => {
    const props = await mockAssignmentAndSubmission({Submission: {unreadCommentCount: 0}})
    const {queryByTestId} = render(<Header {...props} />)
    expect(queryByTestId('unread_comments_badge')).not.toBeInTheDocument()
  })

  it('renders as "Add Comment" by default for nonDigitalSubmission', async () => {
    const props = await mockAssignmentAndSubmission({
      Assignment: {nonDigitalSubmission: true},
      Submission: {...SubmissionMocks.submitted}
    })
    const {getByText} = render(<Header {...props} />)
    expect(getByText('Add Comment')).toBeInTheDocument()
  })

  it('renders as "View Feedback" for observers', async () => {
    const props = await mockAssignmentAndSubmission()
    const {getByText} = render(
      <StudentViewContext.Provider value={{allowChangesToSubmission: false, isObserver: true}}>
        <Header {...props} />
      </StudentViewContext.Provider>
    )
    expect(getByText('View Feedback')).toBeInTheDocument()
  })

  it('renders as "View Feedback" if feedback exists', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: {feedbackForCurrentAttempt: true}
    })
    const {getByText} = render(<Header {...props} />)
    expect(getByText('View Feedback')).toBeInTheDocument()
  })

  it('renders as "View Feedback" if feedback exists for nonDigitalSubmission', async () => {
    const props = await mockAssignmentAndSubmission({
      Assignment: {nonDigitalSubmission: true},
      Submission: {feedbackForCurrentAttempt: true}
    })
    const {getByText} = render(<Header {...props} />)
    expect(getByText('View Feedback')).toBeInTheDocument()
  })

  it('renders as "Add Comment" and disabled if unsubmitted attempt>1', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: {
        ...SubmissionMocks.unsubmitted,
        attempt: 2
      }
    })
    const {getByText} = render(<Header {...props} />)
    expect(getByText('Add Comment').closest('button')).toBeDisabled()
  })

  it('renders additional info button if unsubmitted attempt>1', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: {
        ...SubmissionMocks.unsubmitted,
        attempt: 2
      }
    })
    const {getByRole} = render(<Header {...props} />)
    expect(
      getByRole('button', {
        name: /After the first attempt, you cannot leave comments until you submit the assignment./
      })
    ).toBeInTheDocument()
  })

  it('does not render additional info button if unsubmitted attempt==1', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: {
        ...SubmissionMocks.unsubmitted,
        attempt: 1
      }
    })
    const {queryByRole} = render(<Header {...props} />)
    expect(
      queryByRole('button', {
        name: /After the first attempt, you cannot leave comments until you submit the assignment./
      })
    ).not.toBeInTheDocument()
  })

  it('does not render additional info button if submitted attempt>1', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: {
        ...SubmissionMocks.submitted,
        attempt: 2
      }
    })
    const {queryByRole} = render(<Header {...props} />)
    expect(
      queryByRole('button', {
        name: /After the first attempt, you cannot leave comments until you submit the assignment./
      })
    ).not.toBeInTheDocument()
  })

  it('does not show the unread comments badge if peerReviewModeEnabled is set to true ', async () => {
    const props = await mockAssignmentAndSubmission({Submission: {unreadCommentCount: 1}})
    props.assignment.env.peerReviewModeEnabled = true
    const {queryByTestId} = render(<Header {...props} />)
    expect(queryByTestId('unread_comments_badge')).not.toBeInTheDocument()
  })

  it('shows the unread comments badge if peerReviewModeEnabled is set to false ', async () => {
    const props = await mockAssignmentAndSubmission({Submission: {unreadCommentCount: 1}})
    props.assignment.env.peerReviewModeEnabled = false
    const {getByTestId} = render(<Header {...props} />)
    expect(getByTestId('unread_comments_badge')).toBeInTheDocument()
  })
})
