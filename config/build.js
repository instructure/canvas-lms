({

  // file optimizations
  optimize: "uglify",

  // continue to let Jammit do its thing
  optimizeCss: "none",

  // where to place optimized javascript, relative to this file
  dir: "../public/optimized",

  // where the "app" is, relative to this file
  appDir: "../public/javascripts",

  // base path for modules, relative to appDir
  baseUrl: "./",

  translate: true,

  // paths we have set up (matches require onfig in application.html.erb)
  paths: {
    jquery: 'vendor/jquery-1.6.4',
    jqueryui: 'vendor/jqueryui',
    uploadify: '../flash/uploadify/jquery.uploadify.v2.1.4',
    common: 'compiled/bundles/common'
  },

  // which modules should have their dependencies concatenated into them
  modules: [
    { name: "common" },
    { name: "compiled/bundles/account_settings", exclude: ['common'] },
    { name: "compiled/bundles/account_statistics", exclude: ['common'] },
    { name: "compiled/bundles/alerts", exclude: ['common'] },
    { name: "compiled/bundles/aligned_outcomes", exclude: ['common'] },
    { name: "compiled/bundles/assignmentMuter", exclude: ['common'] },
    { name: "compiled/bundles/assignments", exclude: ['common'] },
    { name: "compiled/bundles/attendance", exclude: ['common'] },
    { name: "compiled/bundles/calendar", exclude: ['common'] },
    { name: "compiled/bundles/calendar_event", exclude: ['common'] },
    { name: "compiled/bundles/collaborations", exclude: ['common'] },
    { name: "compiled/bundles/conferences", exclude: ['common'] },
    { name: "compiled/bundles/content_exports", exclude: ['common'] },
    { name: "compiled/bundles/content_migration", exclude: ['common'] },
    { name: "compiled/bundles/context_modules", exclude: ['common'] },
    { name: "compiled/bundles/course", exclude: ['common'] },
    { name: "compiled/bundles/course_settings", exclude: ['common'] },
    { name: "compiled/bundles/dashboard", exclude: ['common'] },
    { name: "compiled/bundles/datagrid", exclude: ['common'] },
    { name: "compiled/bundles/discussion_replies", exclude: ['common'] },
    { name: "compiled/bundles/edit_rubric", exclude: ['common'] },
    { name: "compiled/bundles/eportfolio", exclude: ['common'] },
    { name: "compiled/bundles/file_inline", exclude: ['common'] },
    { name: "compiled/bundles/full_assignment", exclude: ['common'] },
    { name: "compiled/bundles/full_files", exclude: ['common'] },
    { name: "compiled/bundles/grade_summary", exclude: ['common'] },
    { name: "compiled/bundles/gradebook2", exclude: ['common'] },
    { name: "compiled/bundles/gradebook_history", exclude: ['common'] },
    { name: "compiled/bundles/gradebook_uploads", exclude: ['common'] },
    { name: "compiled/bundles/gradebooks", exclude: ['common'] },
    { name: "compiled/bundles/grading_standards", exclude: ['common'] },
    { name: "compiled/bundles/graphael", exclude: ['common'] },
    { name: "compiled/bundles/groups", exclude: ['common'] },
    { name: "compiled/bundles/jobs", exclude: ['common'] },
    { name: "compiled/bundles/jquery_ui_menu", exclude: ['common'] },
    { name: "compiled/bundles/json2", exclude: ['common'] },
    { name: "compiled/bundles/learning_outcome", exclude: ['common'] },
    { name: "compiled/bundles/learning_outcomes", exclude: ['common'] },
    { name: "compiled/bundles/link_enrollment", exclude: ['common'] },
    { name: "compiled/bundles/manage_avatars", exclude: ['common'] },
    { name: "compiled/bundles/manage_groups", exclude: ['common'] },
    { name: "compiled/bundles/messages", exclude: ['common'] },
    { name: "compiled/bundles/moderate_quiz", exclude: ['common'] },
    { name: "compiled/bundles/plugins", exclude: ['common'] },
    { name: "compiled/bundles/prerequisites_lookup", exclude: ['common'] },
    { name: "compiled/bundles/profile", exclude: ['common'] },
    { name: "compiled/bundles/question_bank", exclude: ['common'] },
    { name: "compiled/bundles/question_banks", exclude: ['common'] },
    { name: "compiled/bundles/quiz_show", exclude: ['common'] },
    { name: "compiled/bundles/quizzes_bundle", exclude: ['common'] },
    { name: "compiled/bundles/quizzes_index", exclude: ['common'] },
    { name: "compiled/bundles/rubric_assessment", exclude: ['common'] },
    { name: "compiled/bundles/section", exclude: ['common'] },
    { name: "compiled/bundles/select_content_dialog", exclude: ['common'] },
    { name: "compiled/bundles/sis_import", exclude: ['common'] },
    { name: "compiled/bundles/site_admin", exclude: ['common'] },
    { name: "compiled/bundles/slickgrid", exclude: ['common'] },
    { name: "compiled/bundles/speed_grader", exclude: ['common'] },
    { name: "compiled/bundles/sub_accounts", exclude: ['common'] },
    { name: "compiled/bundles/syllabus", exclude: ['common'] },
    { name: "compiled/bundles/take_quiz", exclude: ['common'] },
    { name: "compiled/bundles/teacher_activity_report", exclude: ['common'] },
    { name: "compiled/bundles/tool_inline", exclude: ['common'] },
    { name: "compiled/bundles/topic", exclude: ['common'] },
    { name: "compiled/bundles/topics", exclude: ['common'] },
    { name: "compiled/bundles/user", exclude: ['common'] },
    { name: "compiled/bundles/user_lists", exclude: ['common'] },
    { name: "compiled/bundles/user_logins", exclude: ['common'] },
    { name: "compiled/bundles/user_name", exclude: ['common'] },
    { name: "compiled/bundles/user_notes", exclude: ['common'] },
    { name: "compiled/bundles/user_sortable_name", exclude: ['common'] },
    { name: "compiled/bundles/wiki", exclude: ['common'] },
    { name: "compiled/bundles/calendar2", exclude: ['common'] }
  ]
})

