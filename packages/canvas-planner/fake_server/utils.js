const moment = require('moment-timezone');

const getKindaUniqueId = () => Math.floor(Math.random() * (100000 - 1) + 1).toString();

const generateStatus = (overrides) => {
  const statusObject = {
      excused: false,
      graded: false,
      late: false,
      submitted: false,
      missing: false,
      needs_grading: false,
      has_feedback: false
  };

  if (overrides) {
    return Object.assign({}, statusObject, overrides);
  }

  const baseStatusDecider = Math.floor(Math.random() * (10000 - 1)) % 4;
  switch (baseStatusDecider) {
    case 0:
      statusObject.graded = true;
      if (Math.random() > 0.5) {
        statusObject.late = true;
      }
      if (Math.random() < 0.5) {
        statusObject.has_feedback = true;
      }
      break;
    case 1:
      statusObject.excused = true;
      break;
    case 2:
      statusObject.submitted = true;
      if (Math.random() > 0.5) {
        statusObject.late = true;
      }
      if (Math.random() < 0.5) {
        statusObject.needs_grading = true;
      }
      break;
    default:
      if (Math.random() > 0.5) {
        statusObject.missing = true;
      }
      break;
  }

  return statusObject;
};

const createFakeAssignment  = (name, courseId = "1", dueDateTime = moment(), completed = false, status = false) => {
  const id = getKindaUniqueId();

  return {
    id: id, // This is NOT part of the Canvas API but is required for JSON Server
    fake_date_dont_use_me_only_for_sorting: dueDateTime.tz('UTC').format(),
    context_type: "Course",
    course_id: courseId,
    type: "submitting",
    ignore: `/api/v1/users/self/todo/assignment_${id}/submitting?permanent=0`,
    ignore_permanently: `/api/v1/users/self/todo/assignment_${id}/submitting?permanent=1`,
    visible_in_planner: true,
    planner_override: null,
    plannable_type: 'assignment',
    submissions: status,
    plannable: {
      id: id,
      description: "<p>Lorem ipsum etc.</p>",
      due_at: dueDateTime.tz('UTC').format(),
      unlock_at: null,
      lock_at: null,
      points_possible: 50,
      grading_type: "points",
      assignment_group_id: "2",
      grading_standard_id: null,
      created_at: "2017-05-12T15:05:48Z",
      updated_at: "2017-05-12T15:05:48Z",
      peer_reviews: false,
      automatic_peer_reviews: false,
      position: 1,
      grade_group_students_individually: false,
      anonymous_peer_reviews: false,
      group_category_id: null,
      post_to_sis: false,
      moderated_grading: false,
      omit_from_final_grade: false,
      intra_group_peer_reviews: false,
      secure_params: "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9",
      course_id: courseId,
      name: name,
      submission_types: [
        "online_text_entry",
        "online_upload"
      ],
      has_submitted_submissions: completed,
      due_date_required: false,
      max_name_length: 255,
      in_closed_grading_period: false,
      is_quiz_assignment: false,
      muted: false,
      html_url: `/courses/${courseId}/assignments/${id}`,
      published: true,
      only_visible_to_overrides: false,
      locked_for_user: false,
      submissions_download_url: `/courses/${courseId}/assignments/${id}/submissions?zip=1`
    },
    html_url: `/courses/${courseId}/assignments/${id}#submit`
  };
};

const createFakeDiscussion = (name, courseId = "1", dueDateTime = moment(), completed = false, status = false) => {
  const id = getKindaUniqueId();

  return {
    id: id, // This is NOT part of the Canvas API but is required for JSON Server
    fake_date_dont_use_me_only_for_sorting: dueDateTime.tz('UTC').format(),
    context_type: "Course",
    course_id: courseId,
    type: "submitting",
    ignore: `/api/v1/users/self/todo/assignment_${id}/submitting?permanent=0`,
    ignore_permanently: `/api/v1/users/self/todo/assignment_${id}/submitting?permanent=1`,
    visible_in_planner: true,
    planner_override: null,
    plannable_type: 'discussion_topic',
    submissions: status,
    plannable: {
      id: "1",
      title: name,
      last_reply_at: "2017-05-15T16:32:34Z",
      delayed_post_at: null,
      posted_at: "2017-05-15T16:32:34Z",
      assignment_id: id,
      root_topic_id: null,
      position: null,
      podcast_has_student_posts: false,
      discussion_type: "side_comment",
      lock_at: null,
      allow_rating: false,
      only_graders_can_rate: false,
      sort_by_rating: false,
      user_name: "clay@instructure.com",
      discussion_subentry_count: 0,
      permissions: {
        attach: false,
        update: false,
        reply: true,
        delete: false
      },
      require_initial_post: null,
      user_can_see_posts: true,
      podcast_url: null,
      read_state: "unread",
      unread_count: 0,
      subscribed: false,
      topic_children: [],
      attachments: [],
      published: true,
      can_unpublish: false,
      locked: false,
      can_lock: false,
      comments_disabled: false,
      author: {
        id: "1",
        display_name: "Carl Chudyk",
        avatar_image_url: "http://canvas.instructure.com/images/messages/avatar-50.png",
        html_url: `/courses/${courseId}/users/1`
      },
      html_url: `/courses/${courseId}/discussion_topics/${id}`,
      url: `/courses/${courseId}/discussion_topics/${id}`,
      pinned: false,
      group_category_id: null,
      can_group: true,
      locked_for_user: false,
      message: "<p>Some prompt</p>",
      todo_date: dueDateTime.tz('UTC').format(),
      // have to add this because json server doesn't have the capability to do both due_at and todo_date
      due_at: dueDateTime.tz('UTC').format(),
    },
    html_url: `/courses/${courseId}/assignments/${id}#submit`
  };
};

const createFakeQuiz = (name, courseId = "1", dueDateTime = moment(), completed = false, status = false) => {
  const id = getKindaUniqueId();

  return {
    id: id, // This is NOT part of the Canvas API but is required for JSON Server
    fake_date_dont_use_me_only_for_sorting: dueDateTime.tz('UTC').format(),
    context_type: "Course",
    course_id: courseId,
    type: "submitting",
    ignore: `/api/v1/users/self/todo/assignment_${id}/submitting?permanent=0`,
    ignore_permanently: `/api/v1/users/self/todo/assignment_${id}/submitting?permanent=1`,
    visible_in_planner: true,
    planner_override: null,
    plannable_type: 'quiz',
    submissions: status,
    plannable: {
      id: "2",
      title: name,
      html_url: `/courses/${courseId}/quizzes/${id}`,
      mobile_url: `/courses/${courseId}/quizzes/${id}?force_user=1\u0026persist_headless=1`,
      description: "\u003cp\u003easdfasdf\u003c\/p\u003e",
      quiz_type: "assignment",
      time_limit: null,
      shuffle_answers: false,
      show_correct_answers: true,
      scoring_policy: "keep_highest",
      allowed_attempts: 1,
      one_question_at_a_time: false,
      question_count: 0,
      points_possible: 0.0,
      cant_go_back: false,
      ip_filter: null,
      due_at: dueDateTime.tz('UTC').format(),
      lock_at: null,
      unlock_at: null,
      published: true,
      locked_for_user: false,
      hide_results: null,
      show_correct_answers_at: null,
      hide_correct_answers_at: null,
      all_dates: [
        {
          due_at: dueDateTime.tz('UTC').format(),
          unlock_at: null,
          lock_at: null,
          base: true
        }
      ],
      can_update: false,
      require_lockdown_browser: false,
      require_lockdown_browser_for_results: false,
      require_lockdown_browser_monitor: false,
      lockdown_browser_monitor_data: null,
      permissions: {
        read_statistics: false,
        manage: false,
        read: true,
        update: false,
        create: false,
        submit: true,
        preview: false,
        delete: false,
        grade: false,
        review_grades: false,
        view_answer_audits: false
      },
      quiz_reports_url: `/courses/${courseId}/quizzes/${id}/reports`,
      quiz_statistics_url: `/courses/${courseId}/quizzes/${id}/statistics`,
      quiz_submission_versions_html_url: `/courses/${courseId}/quizzes/${id}/submission_versions`,
      assignment_id: 6,
      one_time_results: false,
      assignment_group_id: 1,
      show_correct_answers_last_attempt: false,
      version_number: 2,
      question_types: [],
      has_access_code: false,
      post_to_sis: false
    },
    html_url: `/courses/${courseId}/quizzes/${id}`
  };
};

const createFakeWiki = (name, courseId = "1", dueDateTime = moment(), completed = false, status = false) => {
  const id = getKindaUniqueId();

  return {
    fake_date_dont_use_me_only_for_sorting: dueDateTime.tz('UTC').format(),
    context_type: 'Course',
    course_id: courseId,
    type: 'viewing',
    ignore: `/api/v1/users/self/todo/wiki_page_${id}/viewing?permanent=0`,
    ignore_permanently: `/api/v1/users/self/todo/wiki_page_${id}/viewing?permanent=1`,
    visible_in_planner: true,
    planner_override: null,
    plannable_type: 'wiki_page',
    submissions: status,
    plannable: {
      id: "1",
      title: name,
      created_at: '2017-06-05T14:48:47Z',
      url: 'bgg-wiki',
      editing_roles: 'teachers',
      page_id: id,
      last_edited_by: {
        id: 1,
        display_name: 'Carl',
        avatar_image_url: 'http://canvas.instructure.com/images/messages/avatar-50.png',
        html_url: '/courses/1/users/1'
      },
      published: true,
      hide_from_students: false,
      front_page: false,
      html_url: '/courses/1/pages/bgg-wiki',
      todo_date: dueDateTime.tz('UTC').format(),
      // have to add this because json server doesn't have the capability to do both due_at and todo_date
      due_at: dueDateTime.tz('UTC').format(),
      updated_at: '2017-06-05T14:48:47Z',
      locked_for_user: false,
      body: ''
    },
    html_url: 'bgg-wiki'
  };
};

const createFakeOpportunity = (description = "Random Description", courseId = "1", dueDateTime = moment()) => {
  const id = getKindaUniqueId();

  return {
    id: id,
    description: description,
    due_at: "2017-05-12T15:05:48Z",
    unlock_at: null,
    lock_at: null,
    points_possible: 0,
    grading_type: "points",
    assignment_group_id: 1,
    grading_standard_id: null,
    created_at: "2017-03-09T20:40:35Z",
    updated_at: "2017-04-20T04:02:18Z",
    peer_reviews: false,
    automatic_peer_reviews: false,
    position: 3,
    grade_group_students_individually: false,
    anonymous_peer_reviews: false,
    group_category_id: null,
    post_to_sis: false,
    moderated_grading: false,
    omit_from_final_grade: false,
    intra_group_peer_reviews: false,
    secure_params: "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJsdGlfYXNzaWdubWVudF9pZCI6ImM3MDA1NzAyLTNhZTItNGFiOC05ZTkzLWJhNGY2ZmE1OTA0ZSJ9.3CTWn4eMV8jhXsnGc0u0WndwFtzSls9V8Ge2h8wdUc8",
    course_id: courseId,
    name: "Quiz 2",
    submission_types: [
      "online_quiz"
    ],
    has_submitted_submissions: false,
    due_date_required: false,
    max_name_length: 255, in_closed_grading_period: false,
    is_quiz_assignment: true,
    muted: false,
    html_url: "http://localhost:3000/courses/1/assignments/8",
    quiz_id: 4,
    anonymous_submissions: false,
    published: true,
    only_visible_to_overrides: false,
    locked_for_user: false,
    submissions_download_url: "http://localhost:3000/courses/1/quizzes/4/submissions?zip=1"
  };
};

const createFakeOverride = (plannableId = "1", plannableType = "assignment", userId = "1", completed = "false") => {
  return {
    id: getKindaUniqueId(),
    plannable_type: plannableType,
    plannable_id: plannableId,
    user_id: userId,
    workflow_state: "active",
    deleted_at: null,
    created_at: "2017-03-09T20:40:35Z",
    updated_at: "2017-04-20T04:02:18Z",
    marked_complete: completed,
  };
};

module.exports = {
  createFakeAssignment,
  createFakeDiscussion,
  createFakeQuiz,
  createFakeWiki,
  getKindaUniqueId,
  generateStatus,
  createFakeOpportunity,
  createFakeOverride,
};
