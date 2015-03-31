full_path_glob = '(/*full_path)'

# allow plugins to prepend routes
Dir["{gems,vendor}/plugins/*/config/pre_routes.rb"].each { |pre_routes|
  load pre_routes
}

CanvasRails::Application.routes.draw do
  resources :submission_comments, only: :destroy

  get 'inbox' => 'context#inbox'
  get 'oauth/redirect_proxy' => 'oauth_proxy#redirect_proxy'

  get 'conversations/unread' => 'conversations#index', as: :conversations_unread, redirect_scope: 'unread'
  get 'conversations/starred' => 'conversations#index', as: :conversations_starred, redirect_scope: 'starred'
  get 'conversations/sent' => 'conversations#index', as: :conversations_sent, redirect_scope: 'sent'
  get 'conversations/archived' => 'conversations#index', as: :conversations_archived, redirect_scope: 'archived'
  get 'conversations/find_recipients' => 'search#recipients'

  get 'search/recipients' => 'search#recipients'
  post 'conversations/mark_all_as_read' => 'conversations#mark_all_as_read'
  post 'conversations/watched_intro' => 'conversations#watched_intro'
  get 'conversations/batches' => 'conversations#batches', as: :conversation_batches
  post 'conversations/toggle_new_conversations' => 'conversations#toggle_new_conversations', as: :toggle_new_conversations
  resources :conversations, only: [:index, :show, :update, :create, :destroy] do
    post :add_recipients
    post :add_message
    post :remove_messages
  end

  # So, this will look like:
  # http://instructure.com/register/5R32s9iqwLK75Jbbj0
  match 'register/:nonce' => 'communication_channels#confirm', as: :registration_confirmation, via: [:get, :post]
  # deprecated
  get 'pseudonyms/:id/register/:nonce' => 'communication_channels#confirm', as: :registration_confirmation_deprecated
  post 'confirmations/:user_id/re_send(/:id)' => 'communication_channels#re_send_confirmation', as: :re_send_confirmation, id: nil
  match 'forgot_password' => 'pseudonyms#forgot_password', as: :forgot_password, via: [:get, :post]
  get 'pseudonyms/:pseudonym_id/change_password/:nonce' => 'pseudonyms#confirm_change_password', as: :confirm_change_password
  post 'pseudonyms/:pseudonym_id/change_password/:nonce' => 'pseudonyms#change_password', as: :change_password

  # callback urls for oauth authorization processes
  get 'oauth' => 'users#oauth'
  get 'oauth_success' => 'users#oauth_success'

  get 'mr/:id' => 'info#message_redirect', as: :message_redirect
  get 'help_links' => 'info#help_links'

  concern :question_banks do
    resources :question_banks do
      post :bookmark
      post :reorder
      get :questions
      post :move_questions
      resources :assessment_questions
    end
  end

  concern :groups do
    resources :groups
    resources :group_categories, only: [:create, :update, :destroy]
    get 'group_unassigned_members' => 'groups#unassigned_members'
  end

  concern :files do
    resources :files do
      get 'inline' => 'files#text_show', as: :text_inline
      get 'download' => 'files#show', download: '1'
      get 'download.:type' => 'files#show', as: :typed_download, download: '1'
      get 'preview' => 'files#show', preview: '1'
      post 'inline_view' => 'files#show', inline: '1'
      get 'contents' => 'files#attachment_content', as: :attachment_content
      get 'file_preview' => 'file_previews#show'
      collection do
        get "folder#{full_path_glob}" => 'files#react_files', format: false
        get "search" => 'files#react_files', format: false
        get :quota
        post :reorder
      end
      get ':file_path' => 'files#show_relative', as: :relative_path, file_path: /.+/ #needs to stay below react_files route
    end
  end

  concern :file_images do
    get 'images' => 'files#images'
  end

  concern :relative_files do
    get 'file_contents/:file_path' => 'files#show_relative', as: :relative_file_path, file_path: /.+/
  end

  concern :folders do
    resources :folders do
      get :download
    end
  end

  concern :media do
    get 'media_download' => 'users#media_download'
  end

  concern :users do
    get 'users' => 'context#roster'
    get 'user_services' => 'context#roster_user_services'
    get 'users/:user_id/usage' => 'context#roster_user_usage', as: :user_usage
    get 'users/:id' => 'context#roster_user', as: :user
  end

  concern :announcements do
    resources :announcements
    post 'announcements/external_feeds' => 'announcements#create_external_feed'
    delete 'announcements/external_feeds/:id' => 'announcements#destroy_external_feed', as: :announcements_external_feed
  end

  concern :discussions do
    resources :discussion_topics, only: [:index, :new, :show, :edit, :destroy]
    get 'discussion_topics/:id/:extras' => 'discussion_topics#show', as: :map, extras: /.+/
    resources :discussion_entries
  end

  concern :pages do
    resources :wiki_pages, path: :pages, except: [:update, :destroy], constraints: { id: %r{[^\/]+} } do
      get 'revisions' => 'wiki_pages#revisions', as: :revisions
    end

    get 'wiki' => 'wiki_pages#front_page', as: :wiki
    get 'wiki/:id' => 'wiki_pages#show_redirect', id: /[^\/]+/
    get 'wiki/:id/revisions' => 'wiki_pages#revisions_redirect', id: /[^\/]+/
    get 'wiki/:id/revisions/:revision_id' => 'wiki_pages#revisions_redirect', id: /[^\/]+/
  end

  concern :conferences do
    resources :conferences do
      match :join, via: [:get, :post]
      match :close, via: [:get, :post]
      get :settings
    end
  end

  concern :zip_file_imports do
    resources :zip_file_imports, only: [:new, :create, :show]
    get 'imports/files' => 'content_imports#files', as: :import_files
  end

  # There are a lot of resources that are all scoped to the course level
  # (assignments, files, wiki pages, user lists, forums, etc.).  Many of
  # these resources also apply to groups and individual users.  We call
  # courses, users, groups, or even accounts in this setting, "contexts".
  # There are some helper methods like the before_filter :get_context in application_controller
  # and the application_helper method :context_url to make retrieving
  # these contexts, and also generating context-specific urls, easier.
  resources :courses do
    # DEPRECATED
    get 'self_enrollment/:self_enrollment' => 'courses#self_enrollment', as: :self_enrollment
    post 'self_unenrollment/:self_unenrollment' => 'courses#self_unenrollment', as: :self_unenrollment
    post :restore
    post :backup
    post :unconclude
    get :students
    post :enrollment_invitation
    # this needs to come before the users concern, or users/:id will preempt it
    get 'users/prior' => 'context#prior_users', as: :prior_users
    concerns :users
    get :statistics
    delete 'unenroll/:id' => 'courses#unenroll_user', as: :unenroll
    post 'move_enrollment/:id' => 'courses#move_enrollment', as: :move_enrollment
    delete 'unenroll/:id.:format' => 'courses#unenroll_user', as: :formatted_unenroll
    post 'limit_user_grading/:id' => 'courses#limit_user', as: :limit_user_grading
    delete 'conclude_user/:id' => 'courses#conclude_user', as: :conclude_user_enrollment
    post 'unconclude_user/:id' => 'courses#unconclude_user', as: :unconclude_user_enrollment
    resources :sections, except: [:index, :edit, :new] do
      get 'crosslist/confirm/:new_course_id' => 'sections#crosslist_check', as: :confirm_crosslist
      post :crosslist
      delete 'crosslist' => 'sections#uncrosslist', as: :uncrosslist
    end

    get 'undelete' => 'context#undelete_index', as: :undelete_items
    post 'undelete/:asset_string' => 'context#undelete_item', as: :undelete_item

    get "settings#{full_path_glob}", action: :settings
    get :settings
    get 'details' => 'courses#settings'
    post :re_send_invitations
    post :enroll_users
    post :link_enrollment
    post :update_nav
    resource :gradebook do
      post 'submissions_upload/:assignment_id' => 'gradebooks#submissions_zip_upload', as: :submissions_upload
      collection do
        get :change_gradebook_version
        get :blank_submission
        get :speed_grader
        post :speed_grader_settings
        get :history
        post :update_submission
      end
    end

    get 'gradebook2' => "gradebooks#gradebook2"

    get 'attendance' => 'gradebooks#attendance'
    get 'attendance/:user_id' => 'gradebooks#attendance', as: :attendance_user
    concerns :zip_file_imports
    # DEPRECATED old migration emails pointed the user to this url, leave so the controller can redirect
    get 'imports/list' => 'content_imports#index', as: :import_list
    # DEPRECATED
    get 'imports' => 'content_imports#intro'
    resource :gradebook_upload
    get 'grades' => 'gradebooks#grade_summary', id: nil
    get 'grading_rubrics' => 'gradebooks#grading_rubrics'
    get 'grades/:id' => 'gradebooks#grade_summary', as: :student_grades
    concerns :announcements
    get 'calendar' => 'calendars#show2', as: :old_calendar
    get :locks
    concerns :discussions
    resources :assignments do
      resources :submissions do
        post 'turnitin/resubmit' => 'submissions#resubmit_to_turnitin', as: :resubmit_to_turnitin
        get 'turnitin/:asset_string' => 'submissions#turnitin_report', as: :turnitin_report
      end
      get :rubric
      resource :rubric_association, path: :rubric do
        resources :rubric_assessments, path: :assessments
      end

      get :peer_reviews
      post :assign_peer_reviews
      delete 'peer_reviews/:id' => 'assignments#delete_peer_review', as: :delete_peer_review
      post 'peer_reviews/:id' => 'assignments#remind_peer_review', as: :remind_peer_review
      post 'peer_reviews/users/:reviewer_id' => 'assignments#assign_peer_review', as: :assign_peer_review
      put 'mute' => 'assignments#toggle_mute'

      collection do
        get :syllabus
        get :submissions
      end

      member do
        get :list_google_docs
      end
    end

    resources :grading_standards, only: [:index, :create, :update, :destroy]
    resources :assignment_groups do
      post 'reorder' => 'assignment_groups#reorder_assignments', as: :reorder_assignments
      collection do
        post :reorder
      end
    end

    get 'external_tools/sessionless_launch' => 'external_tools#sessionless_launch'
    resources :external_tools do
      get :resource_selection
      get :homework_submission
      get :finished
      collection do
        get :retrieve
        get :homework_submissions
      end
    end

    get 'lti/basic_lti_launch_request/:message_handler_id', controller: 'lti/message', action: 'basic_lti_launch_request', as: :basic_lti_launch_request
    get 'lti/tool_proxy_registration', controller: 'lti/message', action: 'registration', as: :tool_proxy_registration
    get 'lti/registration_return', controller: 'lti/message', action: 'registration_return', as: :registration_return

    resources :submissions
    resources :calendar_events

    concerns :files, :file_images, :relative_files, :folders
    concerns :groups
    concerns :pages
    concerns :conferences
    concerns :question_banks

    post 'quizzes/publish'   => 'quizzes/quizzes#publish'
    post 'quizzes/unpublish' => 'quizzes/quizzes#unpublish'

    resources :quizzes, controller: 'quizzes/quizzes' do
      get :managed_quiz_data
      get :submission_versions
      get :history
      get :statistics
      get :read_only
      get :submission_html

      resources :quiz_submissions, controller: 'quizzes/quiz_submissions', path: :submissions do
        collection do
          put :backup
        end
        member do
          get :record_answer
          post :record_answer
        end
        resources :events, controller: 'quizzes/quiz_submission_events', path: "log#{full_path_glob}"
      end

      post 'extensions/:user_id' => 'quizzes/quiz_submissions#extensions', as: :extensions
      resources :quiz_questions, controller: 'quizzes/quiz_questions', path: :questions, only: [:create, :update, :destroy, :show]
      resources :quiz_groups, controller: 'quizzes/quiz_groups', path: :groups, only: [:create, :update, :destroy] do
        member do
          post :reorder
        end
      end

      match 'take' => 'quizzes/quizzes#show', take: '1', via: [:get, :post]
      get 'take/questions/:question_id' => 'quizzes/quizzes#show', as: :question, take: '1'
      get :moderate
      get :lockdown_browser_required
    end

    resources :collaborations
    resources :gradebook_uploads
    resources :rubrics
    resources :rubric_associations do
      post 'remind/:assessment_request_id' => 'rubric_assessments#remind', as: :remind_assessee
      resources :rubric_assessments, path: 'assessments'
    end

    get 'outcomes/users/:user_id' => 'outcomes#user_outcome_results', as: :user_outcomes_results
    resources :outcomes do
      post 'alignments/reorder' => 'outcomes#reorder_alignments', as: :reorder_alignments
      get 'alignments/:id' => 'outcomes#alignment_redirect', as: :alignment_redirect
      post 'alignments' => 'outcomes#align', as: :align
      delete 'alignments/:id' => 'outcomes#remove_alignment', as: :remove_alignment
      get 'results' => 'outcomes#outcome_results'
      get 'results/:id' => 'outcomes#outcome_result', as: :result
      get :details
      collection do
        get :list
        post :add_outcome
      end
    end

    resources :outcome_groups, only: [:create, :update, :destroy] do
      post :reorder
    end

    resources :context_modules, path: :modules do
      post 'items' => 'context_modules#add_item', as: :add_item
      post 'reorder' => 'context_modules#reorder_items', as: :reorder
      post 'collapse' => 'context_modules#toggle_collapse', as: :toggle_collapse
      get 'prerequisites/:code' => 'context_modules#content_tag_prerequisites_needing_finishing', as: :prerequisites_needing_finishing
      get 'items/last' => 'context_modules#module_redirect', as: :last_redirect, last: 1
      get 'items/first' => 'context_modules#module_redirect', as: :first_redirect, first: 1
      collection do
        post :reorder
        get :progressions
      end
    end

    resources :content_exports, only: [:create, :index, :destroy, :show]
    get 'modules/items/assignment_info' => 'context_modules#content_tag_assignment_data', as: :context_modules_assignment_info
    get 'modules/items/:id' => 'context_modules#item_redirect', as: :context_modules_item_redirect
    get 'modules/items/sequence/:id' => 'context_modules#item_details', as: :context_modules_item_details
    delete 'modules/items/:id' => 'context_modules#remove_item', as: :context_modules_remove_item
    put 'modules/items/:id' => 'context_modules#update_item', as: :context_modules_update_item
    get 'confirm_action' => 'courses#confirm_action'
    get :copy, as: :start_copy
    post 'copy' => 'courses#copy_course', as: :copy_course
    concerns :media
    get 'user_notes' => 'user_notes#user_notes'
    get 'details/sis_publish' => 'courses#sis_publish_status', as: :sis_publish_status
    post 'details/sis_publish' => 'courses#publish_to_sis', as: :publish_to_sis
    resources :user_lists, only: :create
    post 'reset' => 'courses#reset_content'
    resources :alerts
    post :student_view
    delete 'student_view' => 'courses#leave_student_view'
    delete 'test_student' => 'courses#reset_test_student'
    get 'content_migrations' => 'content_migrations#index'
  end

  get 'quiz_statistics/:quiz_statistics_id/files/:file_id/download' => 'files#show', as: :quiz_statistics_download, download: '1'

  resources :page_views, only: :update
  post 'media_objects' => 'context#create_media_object', as: :create_media_object
  get 'media_objects/kaltura_notifications' => 'context#kaltura_notifications', as: :kaltura_notifications
  get 'media_objects/:id' => 'context#media_object_inline', as: :media_object
  get 'media_objects/:id/redirect' => 'context#media_object_redirect', as: :media_object_redirect
  get 'media_objects/:id/thumbnail' => 'context#media_object_thumbnail', as: :media_object_thumbnail
  get 'media_objects/:media_object_id/info' => 'media_objects#show', as: :media_object_info
  get 'media_objects/:media_object_id/media_tracks/:id' => 'media_tracks#show', as: :show_media_tracks
  post 'media_objects/:media_object_id/media_tracks' => 'media_tracks#create', as: :create_media_tracks
  delete 'media_objects/:media_object_id/media_tracks/:media_track_id' => 'media_tracks#destroy', as: :delete_media_tracks

  get 'external_content/success/:service' => 'external_content#success', as: :external_content_success
  get 'external_content/retrieve/oembed' => 'external_content#oembed_retrieve', as: :external_content_oembed_retrieve
  get 'external_content/cancel/:service' => 'external_content#cancel', as: :external_content_cancel

  # We offer a bunch of atom and ical feeds for the user to get
  # data out of Instructure.  The :feed_code attribute is keyed
  # off of either a user, and enrollment, a course, etc. based on
  # that item's uuid.  In config/initializers/active_record.rb you'll
  # find a feed_code method to generate the code, and in
  # application_controller there's a get_feed_context to get it back out.
  scope '/feeds' do
    get 'calendars/:feed_code' => 'calendar_events_api#public_feed', as: :feeds_calendar
    get 'calendars/:feed_code.:format' => 'calendar_events_api#public_feed', as: :feeds_calendar_format
    get 'forums/:feed_code' => 'discussion_topics#public_feed', as: :feeds_forum
    get 'forums/:feed_code.:format' => 'discussion_topics#public_feed', as: :feeds_forum_format
    get 'topics/:discussion_topic_id/:feed_code' => 'discussion_entries#public_feed', as: :feeds_topic
    get 'topics/:discussion_topic_id/:feed_code.:format' => 'discussion_entries#public_feed', as: :feeds_topic_format
    get 'announcements/:feed_code' => 'announcements#public_feed', as: :feeds_announcements
    get 'announcements/:feed_code.:format' => 'announcements#public_feed', as: :feeds_announcements_format
    get 'courses/:feed_code' => 'courses#public_feed', as: :feeds_course
    get 'courses/:feed_code.:format' => 'courses#public_feed', as: :feeds_course_format
    get 'groups/:feed_code' => 'groups#public_feed', as: :feeds_group
    get 'groups/:feed_code.:format' => 'groups#public_feed', as: :feeds_group_format
    get 'enrollments/:feed_code' => 'courses#public_feed', as: :feeds_enrollment
    get 'enrollments/:feed_code.:format' => 'courses#public_feed', as: :feeds_enrollment_format
    get 'users/:feed_code' => 'users#public_feed', as: :feeds_user
    get 'users/:feed_code.:format' => 'users#public_feed', as: :feeds_user_format
    get 'eportfolios/:eportfolio_id.:format' => 'eportfolios#public_feed', as: :feeds_eportfolio
    get 'conversations/:feed_code' => 'conversations#public_feed', as: :feeds_conversation
    get 'conversations/:feed_code.:format' => 'conversations#public_feed', as: :feeds_conversation_format
  end

  resources :assessment_questions do
    get 'files/:id/download' => 'files#assessment_question_show', as: :map, download: '1'
    get 'files/:id/preview' => 'files#assessment_question_show', preview: '1'
    get 'files/:id/:verifier' => 'files#assessment_question_show', as: :verified_file, download: '1'
  end

  resources :eportfolios, except: :index do
    post :reorder_categories
    post ':eportfolio_category_id/reorder_entries' => 'eportfolios#reorder_entries', as: :reorder_entries
    resources :categories, controller: :eportfolio_categories
    resources :entries, controller: :eportfolio_entries do
      resources :page_comments, path: :comments, only: [:create, :destroy]
      get 'files/:attachment_id' => 'eportfolio_entries#attachment', as: :view_file
      get 'submissions/:submission_id' => 'eportfolio_entries#submission', as: :preview_submission
    end

    get :export, as: :export_portfolio
    get ':category_name' => 'eportfolio_categories#show', as: :named_category
    get ':category_name/:entry_name' => 'eportfolio_entries#show', as: :named_category_entry
  end

  resources :groups do
    concerns :users
    delete 'remove_user/:user_id' => 'groups#remove_user', as: :remove_user
    post :add_user
    get 'accept_invitation/:uuid' => 'groups#accept_invitation', as: :accept_invitation
    get 'members' => 'groups#context_group_members'
    get 'undelete' => 'context#undelete_index', as: :undelete_items
    post 'undelete/:asset_string' => 'context#undelete_item', as: :undelete_item
    concerns :announcements
    concerns :discussions
    resources :calendar_events
    concerns :files, :file_images, :relative_files, :folders
    concerns :zip_file_imports

    resources :external_tools, only: :show do
      collection do
        get :retrieve
      end
    end

    concerns :pages
    concerns :conferences
    concerns :media

    resources :collaborations
    get 'calendar' => 'calendars#show2', as: :old_calendar
  end

  resources :accounts do
    get "settings#{full_path_glob}", action: :settings
    get :settings
    get :admin_tools
    post 'account_users' => 'accounts#add_account_user', as: :add_account_user
    delete 'account_users/:id' => 'accounts#remove_account_user', as: :remove_account_user
    resources :grading_standards, only: [:index, :create, :update, :destroy]
    get :statistics
    get 'statistics/over_time/:attribute' => 'accounts#statistics_graph', as: :statistics_graph
    get 'statistics/over_time/:attribute.:format' => 'accounts#statistics_graph', as: :formatted_statistics_graph
    get :turnitin_confirmation
    resources :permissions, controller: :role_overrides, only: [:index, :create] do
      collection do
        post :add_role
        delete :remove_role
      end
    end

    resources :role_overrides, only: [:index, :create] do
      collection do
        post :add_role
        delete :remove_role
      end
    end

    resources :terms, except: [:show, :new, :edit]
    resources :sub_accounts

    get :avatars
    get :sis_import
    resources :sis_imports, only: [:create, :show, :index], controller: :sis_imports_api
    post 'users' => 'users#create', as: :add_user
    get 'users/:user_id/delete' => 'accounts#confirm_delete_user', as: :confirm_delete_user
    delete 'users/:user_id' => 'accounts#remove_user', as: :delete_user

    # create/delete are handled by specific routes just above
    resources :users, only: [:index, :new, :edit, :show, :update]
    resources :account_notifications, only: [:create, :destroy]
    concerns :announcements
    resources :assignments
    resources :submissions
    put 'account_authorization_configs' => 'account_authorization_configs#update_all', as: :update_all_authorization_configs
    delete 'account_authorization_configs' => 'account_authorization_configs#destroy_all', as: :remove_all_authorization_configs
    resources :account_authorization_configs
    get 'test_ldap_connections' => 'account_authorization_configs#test_ldap_connection'
    get 'test_ldap_binds' => 'account_authorization_configs#test_ldap_bind'
    get 'test_ldap_searches' => 'account_authorization_configs#test_ldap_search'
    match 'test_ldap_logins' => 'account_authorization_configs#test_ldap_login', via: [:get, :post]
    get 'saml_testing' => 'account_authorization_configs#saml_testing'
    get 'saml_testing_stop' => 'account_authorization_configs#saml_testing_stop'

    get 'external_tools/sessionless_launch' => 'external_tools#sessionless_launch'
    resources :external_tools do
      get :finished
      get :resource_selection
      collection do
        get :retrieve
      end
    end

    get 'lti/basic_lti_launch_request/:message_handler_id', controller: 'lti/message', action: 'basic_lti_launch_request', as: :basic_lti_launch_request
    get 'lti/tool_proxy_registration', controller: 'lti/message', action: 'registration', as: :tool_proxy_registration
    get 'lti/registration_return', controller: 'lti/message', action: 'registration_return', as: :registration_return

    get 'outcomes/users/:user_id' => 'outcomes#user_outcome_results', as: :user_outcomes_results
    resources :outcomes do
      get 'results' => 'outcomes#outcome_results'
      get 'results/:id' => 'outcomes#outcome_result', as: :result
      get :details
      collection do
        get :list
        post :add_outcome
      end
    end

    resources :outcome_groups, only: [:create, :update, :destroy] do
      post :reorder
    end

    resources :rubrics
    resources :rubric_associations do
      resources :rubric_assessments, path: 'assessments'
    end

    concerns :files, :file_images, :relative_files, :folders
    concerns :media
    concerns :groups

    resources :outcomes
    get :courses
    get 'courses/:id' => 'accounts#courses_redirect', as: :courses_redirect
    get 'user_notes' => 'user_notes#user_notes'
    resources :alerts
    resources :question_banks do
      post :bookmark
      post :reorder
      get :questions
      post :move_questions
      resources :assessment_questions
    end

    resources :user_lists, only: :create

    member do
      get :statistics
    end
  end

  get 'images/users/:user_id' => 'users#avatar_image', as: :avatar_image
  get 'images/thumbnails/:id/:uuid' => 'files#image_thumbnail', as: :thumbnail_image
  get 'images/thumbnails/show/:id/:uuid' => 'files#show_thumbnail', as: :show_thumbnail_image
  post 'images/users/:user_id/report' => 'users#report_avatar_image', as: :report_avatar_image
  put 'images/users/:user_id' => 'users#update_avatar_image', as: :update_avatar_image
  get 'all_menu_courses' => 'users#all_menu_courses'
  get 'grades' => 'users#grades'
  get 'login' => 'pseudonym_sessions#new'
  post 'login' => 'pseudonym_sessions#create'
  delete 'logout' => 'pseudonym_sessions#destroy'
  get 'logout' => 'pseudonym_sessions#logout_confirm'
  get 'login/cas' => 'pseudonym_sessions#new', as: :cas_login
  post 'login/cas' => 'pseudonym_sessions#cas_logout', as: :cas_logout
  match 'login/otp' => 'pseudonym_sessions#otp_login', as: :otp_login, via: [:get, :post]
  get 'login/:account_authorization_config_id' => 'pseudonym_sessions#new', as: :aac_login
  delete 'users/:user_id/mfa' => 'pseudonym_sessions#disable_otp_login', as: :disable_mfa
  get 'file_session/clear' => 'pseudonym_sessions#clear_file_session', as: :clear_file_session
  get 'register' => 'users#new'
  get 'register_from_website' => 'users#new'
  get 'enroll/:self_enrollment_code' => 'self_enrollments#new', as: :enroll
  get 'services' => 'users#services'
  get 'search/bookmarks' => 'users#bookmark_search', as: :bookmark_search
  get 'search/rubrics' => 'search#rubrics'
  get 'search/all_courses' => 'search#all_courses'
  delete 'tours/dismiss/:name' => 'tours#dismiss', as: :dismiss_tour
  delete 'tours/dismiss/session/:name' => 'tours#dismiss_session', as: :dismiss_tour_session
  resources :users do
    match 'masquerade', via: [:get, :post]
    delete :delete
    concerns :files, :file_images
    concerns :zip_file_imports

    resources :page_views, only: :index
    resources :folders do
      get :download
    end

    resources :calendar_events
    get 'external_tools/:id' => 'users#external_tool', as: :external_tool
    resources :rubrics
    resources :rubric_associations do
      resources :rubric_assessments, path: :assessments
    end

    resources :pseudonyms, except: :index
    resources :question_banks, only: :index
    get :assignments_needing_grading
    get :assignments_needing_submitting
    get :admin_merge
    post :merge
    get :grades
    resources :user_notes
    get :manageable_courses
    get 'outcomes' => 'outcomes#user_outcome_results'
    get 'teacher_activity/course/:course_id' => 'users#teacher_activity', as: :course_teacher_activity
    get 'teacher_activity/student/:student_id' => 'users#teacher_activity', as: :student_teacher_activity
    get :media_download
    resources :messages, only: [:index, :create] do
      get :html_message
    end
  end

  get 'show_message_template' => 'messages#show_message_template'
  get 'message_templates' => 'messages#templates'
  resource :profile, controller: :profile, only: [:show, :update] do
    resources :pseudonyms, except: :index
    resources :tokens, except: :index
    member do
      put :update_profile
      get :communication
      put :communication_update
      get :settings
      get :observees
    end
  end

  scope '/profile' do
    post 'toggle_disable_inbox' => 'profile#toggle_disable_inbox'
    get 'profile_pictures' => 'profile#profile_pics', as: :profile_pics
    delete 'user_services/:id' => 'users#delete_user_service', as: :profile_user_service
    post 'user_services' => 'users#create_user_service', as: :profile_create_user_service
  end

  get 'about/:id' => 'profile#show', as: :user_profile
  resources :communication_channels
  resource :pseudonym_session

  get '' => 'users#user_dashboard', as: 'dashboard'
  get 'dashboard-sidebar' => 'users#dashboard_sidebar', as: :dashboard_sidebar
  post 'toggle_dashboard' => 'users#toggle_dashboard'
  get 'styleguide' => 'info#styleguide'
  get 'old_styleguide' => 'info#old_styleguide'
  root to: 'users#user_dashboard', as: 'root', via: :get
  # backwards compatibility with the old /dashboard url
  get 'dashboard' => 'users#user_dashboard', as: :dashboard_redirect

  # Thought this idea of having dashboard-scoped urls was a good idea at the
  # time... now I'm not as big a fan.
  resource :dashboard, only: [] do
    resources :content_exports, path: :data_exports
  end

  scope '/dashboard' do
    delete 'account_notifications/:id' => 'users#close_notification', as: :dashboard_close_notification
    get 'eportfolios' => 'eportfolios#user_index', as: :dashboard_eportfolios
    post 'comment_session' => 'services_api#start_kaltura_session', as: :dashboard_comment_session
    delete 'ignore_stream_item/:id' => 'users#ignore_stream_item', as: :dashboard_ignore_stream_item
  end

  resources :plugins, only: [:index, :show, :update]

  get 'calendar' => 'calendars#show2'
  get 'calendar2' => 'calendars#show2'
  get 'course_sections/:course_section_id/calendar_events/:id' => 'calendar_events#show', as: :course_section_calendar_event
  get 'files' => 'files#index'
  get "files/folder#{full_path_glob}", controller: 'files', action: 'react_files', format: false
  get "files/search", controller: 'files', action: 'react_files', format: false
  get 'files/s3_success/:id' => 'files#s3_success', as: :s3_success
  get 'files/:id/public_url' => 'files#public_url', as: :public_url
  get 'files/preflight' => 'files#preflight', as: :file_preflight
  post 'files/pending' => 'files#create_pending', as: :file_create_pending
  resources :assignments, only: :index do
    resources :files, only: [] do
      post 'inline_view' => 'files#show', inline: '1'
    end
  end

  resources :appointment_groups, only: [:index, :show]

  post 'errors' => 'info#record_error'
  resources :errors, only: [:show, :index], path: :error_reports

  get 'health_check' => 'info#health_check'

  get 'browserconfig.xml', to: 'info#browserconfig', defaults: { format: 'xml' }

  post 'object_snippet' => 'context#object_snippet'
  post 'saml_consume' => 'pseudonym_sessions#saml_consume'
  get 'saml_logout' => 'pseudonym_sessions#saml_logout'
  get 'saml_meta_data' => 'accounts#saml_meta_data'

  # Routes for course exports
  get 'xsd/:version.xsd' => 'content_exports#xml_schema'
  resources :jobs, only: [:index, :show] do
    collection do
      post 'batch_update'
    end
  end

  get 'equation_images/:id' => 'equation_images#show', as: :equation_images, id: /.+/

  # assignments at the top level (without a context) -- we have some specs that
  # assert these routes exist, but just 404. I'm not sure we ever actually want
  # top-level assignments available, maybe we should change the specs instead.
  resources :assignments, only: [:index, :show]

  resources :files do
    get 'download' => 'files#show', download: '1'
  end

  resources :developer_keys, only: :index

  resources :rubrics do
    resources :rubric_assessments, path: :assessments
  end

  post 'selection_test' => 'external_content#selection_test'

  resources :quiz_submissions do
    concerns :files
  end

  get 'courses/:course_id/outcome_rollups' => 'outcome_results#rollups', as: 'course_outcome_rollups'

  get 'terms_of_use' => 'legal_information#terms_of_use', as: 'terms_of_use_redirect'
  get 'privacy_policy' => 'legal_information#privacy_policy', as: 'privacy_policy_redirect'

  ### API routes ###

  # TODO: api routes can't yet take advantage of concerns for DRYness, because of
  # the way ApiRouteSet works. For now we get around it by defining methods
  # inline in the routes file, but getting concerns working would rawk.
  ApiRouteSet::V1.draw(self) do
    scope(controller: :courses) do
      get 'courses', action: :index, as: 'courses'
      put 'courses/:id', action: :update
      get 'courses/:id', action: :show, as: 'course'
      delete 'courses/:id', action: :destroy
      post 'accounts/:account_id/courses', action: :create
      get 'courses/:course_id/students', action: :students
      get 'courses/:course_id/settings', action: :settings, as: 'course_settings'
      put 'courses/:course_id/settings', action: :update_settings
      get 'courses/:course_id/recent_students', action: :recent_students, as: 'course_recent_students'
      get 'courses/:course_id/users', action: :users, as: 'course_users'
      # this api endpoint has been removed, it was redundant with just courses#users
      # we keep it around for backward compatibility though
      get 'courses/:course_id/search_users', action: :users
      get 'courses/:course_id/users/:id', action: :user, as: 'course_user'
      get 'courses/:course_id/activity_stream', action: :activity_stream, as: 'course_activity_stream'
      get 'courses/:course_id/activity_stream/summary', action: :activity_stream_summary, as: 'course_activity_stream_summary'
      get 'courses/:course_id/todo', action: :todo_items
      post 'courses/:course_id/preview_html', action: :preview_html
      post 'courses/:course_id/course_copy', controller: :content_imports, action: :copy_course_content
      get 'courses/:course_id/course_copy/:id', controller: :content_imports, action: :copy_course_status, as: :course_copy_status
      get  'courses/:course_id/files', controller: :files, action: :api_index, as: 'course_files'
      post 'courses/:course_id/files', action: :create_file, as: 'course_create_file'
      get 'courses/:course_id/folders', controller: :folders, action: :list_all_folders, as: 'course_folders'
      post 'courses/:course_id/folders', controller: :folders, action: :create
      get 'courses/:course_id/folders/by_path/*full_path', controller: :folders, action: :resolve_path
      get 'courses/:course_id/folders/by_path', controller: :folders, action: :resolve_path
      get  'courses/:course_id/folders/:id', controller: :folders, action: :show, as: 'course_folder'
      put  'accounts/:account_id/courses', action: :batch_update
      post 'courses/:course_id/ping', action: :ping, as: 'course_ping'

      get 'courses/:course_id/link_validation', action: :link_validation
      post 'courses/:course_id/link_validation', action: :start_link_validation

      post 'courses/:course_id/reset_content', :action => :reset_content
    end

    scope(controller: :account_notifications) do
      post 'accounts/:account_id/account_notifications', action: :create, as: 'account_notification'
      get 'accounts/:account_id/users/:user_id/account_notifications', action: :user_index, as: 'user_account_notifications'
      delete 'accounts/:account_id/users/:user_id/account_notifications/:id', action: :user_close_notification, as: 'user_account_notification'
    end

    scope(controller: :tabs) do
      get "courses/:course_id/tabs", action: :index, as: 'course_tabs'
      get "groups/:group_id/tabs", action: :index, as: 'group_tabs'
      put "courses/:course_id/tabs/:tab_id", action: :update
    end

    scope(controller: :sections) do
      get 'courses/:course_id/sections', action: :index, as: 'course_sections'
      get 'courses/:course_id/sections/:id', action: :show, as: 'course_section'
      get 'sections/:id', action: :show
      post 'courses/:course_id/sections', action: :create
      put 'sections/:id', action: :update
      delete 'sections/:id', action: :destroy
      post 'sections/:id/crosslist/:new_course_id', action: :crosslist
      delete 'sections/:id/crosslist', action: :uncrosslist
    end

    scope(controller: :enrollments_api) do
      get  'courses/:course_id/enrollments', action: :index, as: 'course_enrollments'
      get  'sections/:section_id/enrollments', action: :index, as: 'section_enrollments'
      get  'users/:user_id/enrollments', action: :index, as: 'user_enrollments'
      get  'accounts/:account_id/enrollments/:id', action: :show, as: 'enrollment'

      post 'courses/:course_id/enrollments', action: :create
      post 'sections/:section_id/enrollments', action: :create

      delete 'courses/:course_id/enrollments/:id', action: :destroy
    end

    scope(controller: :terms_api) do
      get 'accounts/:account_id/terms', action: :index, as: 'enrollment_terms'
    end

    scope(controller: :terms) do
      post 'accounts/:account_id/terms', action: :create
      put 'accounts/:account_id/terms/:id', action: :update
      delete 'accounts/:account_id/terms/:id', action: :destroy
    end

    scope(controller: :authentication_audit_api) do
      get 'audit/authentication/logins/:login_id', action: :for_login, as: 'audit_authentication_login'
      get 'audit/authentication/accounts/:account_id', action: :for_account, as: 'audit_authentication_account'
      get 'audit/authentication/users/:user_id', action: :for_user, as: 'audit_authentication_user'
    end

    scope(controller: :grade_change_audit_api) do
      get 'audit/grade_change/assignments/:assignment_id', action: :for_assignment, as: 'audit_grade_change_assignment'
      get 'audit/grade_change/courses/:course_id', action: :for_course, as: 'audit_grade_change_course'
      get 'audit/grade_change/students/:student_id', action: :for_student, as: 'audit_grade_change_student'
      get 'audit/grade_change/graders/:grader_id', action: :for_grader, as: 'audit_grade_change_grader'
    end

    scope(controller: :course_audit_api) do
      get 'audit/course/courses/:course_id', action: :for_course, as: 'audit_course_for_course'
    end

    scope(controller: :assignments_api) do
      get 'courses/:course_id/assignments', action: :index, as: 'course_assignments'
      get 'courses/:course_id/assignments/:id', action: :show, as: 'course_assignment'
      post 'courses/:course_id/assignments', action: :create
      put 'courses/:course_id/assignments/:id', action: :update
      delete 'courses/:course_id/assignments/:id', action: :destroy, controller: :assignments
    end

    scope(controller: :assignment_overrides) do
      get 'courses/:course_id/assignments/:assignment_id/overrides', action: :index
      post 'courses/:course_id/assignments/:assignment_id/overrides', action: :create
      get 'courses/:course_id/assignments/:assignment_id/overrides/:id', action: :show, as: 'assignment_override'
      put 'courses/:course_id/assignments/:assignment_id/overrides/:id', action: :update
      delete 'courses/:course_id/assignments/:assignment_id/overrides/:id', action: :destroy
      get 'sections/:course_section_id/assignments/:assignment_id/override', action: :section_alias
      get 'groups/:group_id/assignments/:assignment_id/override', action: :group_alias
    end

    scope(controller: :submissions_api) do
      def submissions_api(context, path_prefix = context)
        post "#{context.pluralize}/:#{context}_id/submissions/update_grades", action: :bulk_update
        put "#{context.pluralize}/:#{context}_id/assignments/:assignment_id/submissions/:user_id/read", action: :mark_submission_read, as: "#{context}_submission_mark_read"
        delete "#{context.pluralize}/:#{context}_id/assignments/:assignment_id/submissions/:user_id/read", action: :mark_submission_unread, as: "#{context}_submission_mark_unread"
        get "#{context.pluralize}/:#{context}_id/assignments/:assignment_id/submissions", action: :index, as: "#{path_prefix}_assignment_submissions"
        get "#{context.pluralize}/:#{context}_id/students/submissions", controller: :submissions_api, action: :for_students, as: "#{path_prefix}_student_submissions"
        get "#{context.pluralize}/:#{context}_id/assignments/:assignment_id/submissions/:user_id", action: :show, as: "#{path_prefix}_assignment_submission"
        post "#{context.pluralize}/:#{context}_id/assignments/:assignment_id/submissions", action: :create, controller: :submissions
        post "#{context.pluralize}/:#{context}_id/assignments/:assignment_id/submissions/:user_id/files", action: :create_file
        put "#{context.pluralize}/:#{context}_id/assignments/:assignment_id/submissions/:user_id", action: :update
        post "#{context.pluralize}/:#{context}_id/assignments/:assignment_id/submissions/update_grades", action: :bulk_update
      end
      submissions_api("course")
      submissions_api("section", "course_section")
    end

    post '/courses/:course_id/assignments/:assignment_id/submissions/:user_id/comments/files',
      action: :create_file, controller: :submission_comments_api

    scope(controller: :gradebook_history_api) do
      get "courses/:course_id/gradebook_history/days", action: :days, as: 'gradebook_history'
      get "courses/:course_id/gradebook_history/feed", action: :feed, as: 'gradebook_history_feed'
      get "courses/:course_id/gradebook_history/:date", action: :day_details, as: 'gradebook_history_for_day'
      get "courses/:course_id/gradebook_history/:date/graders/:grader_id/assignments/:assignment_id/submissions", action: :submissions, as: 'gradebook_history_submissions'
    end

    get 'courses/:course_id/assignment_groups', controller: :assignment_groups, action: :index
    scope(controller: :assignment_groups_api) do
      resources :assignment_groups, path: "courses/:course_id/assignment_groups", name_prefix: "course_", except: :index
    end

    scope(controller: :discussion_topics) do
      get 'courses/:course_id/discussion_topics', action: :index, as: 'course_discussion_topics'
      get 'groups/:group_id/discussion_topics', action: :index, as: 'group_discussion_topics'
    end

    scope(controller: :content_migrations) do
      %w(account course group user).each do |context|
        get "#{context.pluralize}/:#{context}_id/content_migrations/migrators", action: :available_migrators, as: "#{context}_content_migration_migrators_list"
        get "#{context.pluralize}/:#{context}_id/content_migrations/:id", action: :show, as: "#{context}_content_migration"
        get "#{context.pluralize}/:#{context}_id/content_migrations", action: :index, as: "#{context}_content_migration_list"
        post "#{context.pluralize}/:#{context}_id/content_migrations", action: :create, as: "#{context}_content_migration_create"
        put "#{context.pluralize}/:#{context}_id/content_migrations/:id", action: :update, as: "#{context}_content_migration_update"
        get "#{context.pluralize}/:#{context}_id/content_migrations/:id/selective_data", action: :content_list, as: "#{context}_content_migration_selective_data"
      end
    end

    scope(controller: :migration_issues) do
      %w(account course group user).each do |context|
        get "#{context.pluralize}/:#{context}_id/content_migrations/:content_migration_id/migration_issues/:id", action: :show, as: "#{context}_content_migration_migration_issue"
        get "#{context.pluralize}/:#{context}_id/content_migrations/:content_migration_id/migration_issues", action: :index, as: "#{context}_content_migration_migration_issue_list"
        post "#{context.pluralize}/:#{context}_id/content_migrations/:content_migration_id/migration_issues", action: :create, as: "#{context}_content_migration_migration_issue_create"
        put "#{context.pluralize}/:#{context}_id/content_migrations/:content_migration_id/migration_issues/:id", action: :update, as: "#{context}_content_migration_migration_issue_update"
      end
    end

    scope(controller: :discussion_topics_api) do
      def topic_routes(context)
        get "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id", action: :show, as: "#{context}_discussion_topic"
        post "#{context.pluralize}/:#{context}_id/discussion_topics", controller: :discussion_topics, action: :create
        put "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id", controller: :discussion_topics, action: :update
        post "#{context.pluralize}/:#{context}_id/discussion_topics/reorder", controller: :discussion_topics, action: :reorder
        delete "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id", controller: :discussion_topics, action: :destroy

        get "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/view", action: :view, as: "#{context}_discussion_topic_view"

        get "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/entry_list", action: :entry_list, as: "#{context}_discussion_topic_entry_list"
        post "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/entries", action: :add_entry, as: "#{context}_discussion_add_entry"
        get "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/entries", action: :entries, as: "#{context}_discussion_entries"
        post "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/entries/:entry_id/replies", action: :add_reply, as: "#{context}_discussion_add_reply"
        get "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/entries/:entry_id/replies", action: :replies, as: "#{context}_discussion_replies"
        put "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/entries/:id", controller: :discussion_entries, action: :update, as: "#{context}_discussion_update_reply"
        delete "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/entries/:id", controller: :discussion_entries, action: :destroy, as: "#{context}_discussion_delete_reply"

        put "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/read", action: :mark_topic_read, as: "#{context}_discussion_topic_mark_read"
        delete "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/read", action: :mark_topic_unread, as: "#{context}_discussion_topic_mark_unread"
        put "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/read_all", action: :mark_all_read, as: "#{context}_discussion_topic_mark_all_read"
        delete "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/read_all", action: :mark_all_unread, as: "#{context}_discussion_topic_mark_all_unread"
        put "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/entries/:entry_id/read", action: :mark_entry_read, as: "#{context}_discussion_topic_discussion_entry_mark_read"
        delete "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/entries/:entry_id/read", action: :mark_entry_unread, as: "#{context}_discussion_topic_discussion_entry_mark_unread"
        put "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/subscribed", action: :subscribe_topic, as: "#{context}_discussion_topic_subscribe"
        delete "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/subscribed", action: :unsubscribe_topic, as: "#{context}_discussion_topic_unsubscribe"
      end
      topic_routes("course")
      topic_routes("group")
    end

    scope(controller: :collaborations) do
      get 'collaborations/:id/members', action: :members, as: 'collaboration_members'
    end

    scope(controller: :external_tools) do
      def et_routes(context)
        get "#{context}s/:#{context}_id/external_tools/sessionless_launch", action: :generate_sessionless_launch, as: "#{context}_external_tool_sessionless_launch"
        get "#{context}s/:#{context}_id/external_tools/:external_tool_id", action: :show, as: "#{context}_external_tool_show"
        get "#{context}s/:#{context}_id/external_tools", action: :index, as: "#{context}_external_tools"
        post "#{context}s/:#{context}_id/external_tools", action: :create, as: "#{context}_external_tools_create"
        put "#{context}s/:#{context}_id/external_tools/:external_tool_id", action: :update, as: "#{context}_external_tools_update"
        delete "#{context}s/:#{context}_id/external_tools/:external_tool_id", action: :destroy, as: "#{context}_external_tools_delete"
      end
      et_routes("course")
      et_routes("account")
    end

    scope(controller: 'lti/lti_apps') do
      def et_routes(context)
        get "#{context}s/:#{context}_id/lti_apps/launch_definitions", action: :launch_definitions, as: "#{context}_launch_definitions"
        get "#{context}s/:#{context}_id/lti_apps", action: :index, as: "#{context}_app_definitions"
      end
      et_routes("course")
      et_routes("account")
    end

    scope(controller: 'lti/tool_proxy') do
      def et_routes(context)
        delete "#{context}s/:#{context}_id/tool_proxies/:tool_proxy_id", action: :destroy, as: "#{context}_delete_tool_proxy"
        put "#{context}s/:#{context}_id/tool_proxies/:tool_proxy_id", action: :update, as: "#{context}_update_tool_proxy"
      end
      et_routes("course")
      et_routes("account")
    end

    scope(controller: :external_feeds) do
      def ef_routes(context)
        get "#{context}s/:#{context}_id/external_feeds", action: :index, as: "#{context}_external_feeds"
        post "#{context}s/:#{context}_id/external_feeds", action: :create, as: "#{context}_external_feeds_create"
        delete "#{context}s/:#{context}_id/external_feeds/:external_feed_id", action: :destroy, as: "#{context}_external_feeds_delete"
      end
      ef_routes("course")
      ef_routes("group")
    end

    scope(controller: :sis_imports_api) do
      post 'accounts/:account_id/sis_imports', action: :create
      get 'accounts/:account_id/sis_imports/:id', action: :show
      get 'accounts/:account_id/sis_imports', action: :index
    end

    scope(controller: :users) do
      get 'users/self/activity_stream', action: :activity_stream, as: 'user_activity_stream'
      get 'users/activity_stream', action: :activity_stream # deprecated
      get 'users/self/activity_stream/summary', action: :activity_stream_summary, as: 'user_activity_stream_summary'
      delete 'users/self/activity_stream/:id', action: 'ignore_stream_item'
      delete 'users/self/activity_stream', action: 'ignore_all_stream_items'

      put "users/:user_id/followers/self", action: :follow
      delete "users/:user_id/followers/self", action: :unfollow

      get 'users/self/todo', action: :todo_items
      get 'users/self/upcoming_events', action: :upcoming_events

      delete 'users/self/todo/:asset_string/:purpose', action: :ignore_item, as: 'users_todo_ignore'
      post 'accounts/:account_id/users', action: :create
      get 'accounts/:account_id/users', action: :index, as: 'account_users'

      get 'users/:id', action: :api_show
      put 'users/:id', action: :update
      post 'users/:user_id/files', action: :create_file

      get  'users/:user_id/files', controller: :files, action: :api_index, as: 'user_files'
      get 'users/:user_id/folders', controller: :folders, action: :list_all_folders, as: 'user_folders'
      post 'users/:user_id/folders', controller: :folders, action: :create
      get 'users/:user_id/folders/by_path/*full_path', controller: :folders, action: :resolve_path
      get 'users/:user_id/folders/by_path', controller: :folders, action: :resolve_path
      get 'users/:user_id/folders/:id', controller: :folders, action: :show, as: 'user_folder'

      get 'users/:id/settings', controller: 'users', action: 'settings'
      put 'users/:id/settings', controller: 'users', action: 'settings', as: 'user_settings'

      put 'users/:id/merge_into/:destination_user_id', controller: 'users', action: 'merge_into'
      put 'users/:id/merge_into/accounts/:destination_account_id/users/:destination_user_id', controller: 'users', action: 'merge_into'

      scope(controller: :user_observees) do
        get    'users/:user_id/observees', action: :index, as: 'user_observees'
        post   'users/:user_id/observees', action: :create
        get    'users/:user_id/observees/:observee_id', action: :show, as: 'user_observee'
        put    'users/:user_id/observees/:observee_id', action: :update
        delete 'users/:user_id/observees/:observee_id', action: :destroy
      end
    end

    scope(controller: :custom_data) do
      glob = '(/*scope)'
      get "users/:user_id/custom_data#{glob}", action: 'get_data'
      put "users/:user_id/custom_data#{glob}", action: 'set_data'
      delete "users/:user_id/custom_data#{glob}", action: 'delete_data'
    end

    scope(controller: :pseudonyms) do
      get 'accounts/:account_id/logins', action: :index, as: 'account_pseudonyms'
      get 'users/:user_id/logins', action: :index, as: 'user_pseudonyms'
      post 'accounts/:account_id/logins', action: :create
      put 'accounts/:account_id/logins/:id', action: :update
      delete 'users/:user_id/logins/:id', action: :destroy
    end

    scope(controller: :accounts) do
      get 'accounts', action: :index, as: :accounts
      get 'course_accounts', :action => :course_accounts, :as => :course_accounts
      get 'accounts/:id', action: :show, as: :account
      put 'accounts/:id', action: :update
      get 'accounts/:account_id/courses', action: :courses_api, as: 'account_courses'
      get 'accounts/:account_id/sub_accounts', action: :sub_accounts, as: 'sub_accounts'
      get 'accounts/:account_id/courses/:id', controller: :courses, action: :show, as: 'account_course_show'
      delete 'accounts/:account_id/users/:user_id', action: :remove_user
    end

    scope(controller: :sub_accounts) do
      post 'accounts/:account_id/sub_accounts', action: :create
    end

    scope(controller: :role_overrides) do
      get 'accounts/:account_id/roles', action: :api_index, as: 'account_roles'
      get 'accounts/:account_id/roles/:id', action: :show
      post 'accounts/:account_id/roles', action: :add_role
      post 'accounts/:account_id/roles/:id/activate', action: :activate_role
      put 'accounts/:account_id/roles/:id', action: :update
      delete 'accounts/:account_id/roles/:id', action: :remove_role
      get 'accounts/:account_id/permissions/:permission', action: :check_account_permission
    end

    scope(controller: :account_reports) do
      get 'accounts/:account_id/reports/:report', action: :index
      get 'accounts/:account_id/reports', action: :available_reports
      get 'accounts/:account_id/reports/:report/:id', action: :show
      post 'accounts/:account_id/reports/:report', action: :create, as: 'account_create_report'
      delete 'accounts/:account_id/reports/:report/:id', action: :destroy
    end

    scope(controller: :admins) do
      post 'accounts/:account_id/admins', action: :create
      delete 'accounts/:account_id/admins/:user_id', action: :destroy
      get 'accounts/:account_id/admins', action: :index, as: 'account_admins'
    end

    scope(controller: :account_authorization_configs) do
      get 'accounts/:account_id/account_authorization_configs/discovery_url', action: :show_discovery_url
      put 'accounts/:account_id/account_authorization_configs/discovery_url', action: :update_discovery_url, as: 'account_update_discovery_url'
      delete 'accounts/:account_id/account_authorization_configs/discovery_url', action: :destroy_discovery_url, as: 'account_destroy_discovery_url'

      get 'accounts/:account_id/account_authorization_configs', action: :index
      get 'accounts/:account_id/account_authorization_configs/:id', action: :show
      post 'accounts/:account_id/account_authorization_configs', action: :create, as: 'account_create_aac'
      put 'accounts/:account_id/account_authorization_configs/:id', action: :update, as: 'account_update_aac'
      delete 'accounts/:account_id/account_authorization_configs/:id', action: :destroy, as: 'account_delete_aac'
    end

    get 'users/:user_id/page_views', controller: :page_views, action: :index, as: 'user_page_views'
    get 'users/:user_id/profile', controller: :profile, action: :settings
    get 'users/:user_id/avatars', controller: :profile, action: :profile_pics

    # deprecated routes, second one is solely for YARD. preferred API is api/v1/search/recipients
    get 'conversations/find_recipients', controller: :search, action: :recipients
    get 'conversations/find_recipients', controller: :conversations, action: :find_recipients

    scope(controller: :conversations) do
      get 'conversations', action: :index, as: 'conversations'
      post 'conversations', action: :create
      post 'conversations/mark_all_as_read', action: :mark_all_as_read
      get 'conversations/batches', action: :batches, as: 'conversations_batches'
      get 'conversations/unread_count', action: :unread_count
      get 'conversations/:id', action: :show
      put 'conversations/:id', action: :update # stars, subscribed-ness, workflow_state
      delete 'conversations/:id', action: :destroy
      post 'conversations/:id/add_message', action: :add_message
      post 'conversations/:id/add_recipients', action: :add_recipients
      post 'conversations/:id/remove_messages', action: :remove_messages
      put 'conversations', action: :batch_update
      delete 'conversations/:id/delete_for_all', action: :delete_for_all
    end

    scope(controller: :communication_channels) do
      get 'users/:user_id/communication_channels', action: :index, as: 'communication_channels'
      post 'users/:user_id/communication_channels', action: :create
      delete 'users/:user_id/communication_channels/:id', action: :destroy
      delete 'users/:user_id/communication_channels/:type/:address', action: :destroy, constraints: { address: %r{[^/?]+} }
    end

    scope(controller: :notification_preferences) do
      get 'users/:user_id/communication_channels/:communication_channel_id/notification_preferences', action: :index
      get 'users/:user_id/communication_channels/:type/:address/notification_preferences', action: :index, constraints: { address: %r{[^/?]+} }
      get 'users/:user_id/communication_channels/:communication_channel_id/notification_preferences/:notification', action: :show
      get 'users/:user_id/communication_channels/:type/:address/notification_preferences/:notification', action: :show, constraints: { address: %r{[^/?]+} }
      put 'users/self/communication_channels/:communication_channel_id/notification_preferences/:notification', action: :update
      put 'users/self/communication_channels/:type/:address/notification_preferences/:notification', action: :update, constraints: { address: %r{[^/?]+} }
      put 'users/self/communication_channels/:communication_channel_id/notification_preferences', action: :update_all
      put 'users/self/communication_channels/:type/:address/notification_preferences', action: :update_all, constraints: { address: %r{[^/?]+} }
    end

    scope(controller: :comm_messages_api) do
      get 'comm_messages', action: :index, as: 'comm_messages'
    end

    scope(controller: :services_api) do
      get 'services/kaltura', action: :show_kaltura_config
      post 'services/kaltura_session', action: :start_kaltura_session
    end

    scope(controller: :calendar_events_api) do
      get 'calendar_events', action: :index, as: 'calendar_events'
      post 'calendar_events', action: :create
      get 'calendar_events/:id', action: :show, as: 'calendar_event'
      put 'calendar_events/:id', action: :update
      delete 'calendar_events/:id', action: :destroy
      post 'calendar_events/:id/reservations', action: :reserve
      post 'calendar_events/:id/reservations/:participant_id', action: :reserve, as: 'calendar_event_reserve'
    end

    scope(controller: :appointment_groups) do
      get 'appointment_groups', action: :index, as: 'appointment_groups'
      post 'appointment_groups', action: :create
      get 'appointment_groups/:id', action: :show, as: 'appointment_group'
      put 'appointment_groups/:id', action: :update
      delete 'appointment_groups/:id', action: :destroy
      get 'appointment_groups/:id/users', action: :users, as: 'appointment_group_users'
      get 'appointment_groups/:id/groups', action: :groups, as: 'appointment_group_groups'
    end

    scope(controller: :groups) do
      resources :groups, except: :index
      get 'users/self/groups', action: :index, as: "current_user_groups"
      get 'accounts/:account_id/groups', action: :context_index, as: 'account_user_groups'
      get 'courses/:course_id/groups', action: :context_index, as: 'course_user_groups'
      get 'groups/:group_id/users', action: :users, as: 'group_users'
      post 'groups/:group_id/invite', action: :invite
      post 'groups/:group_id/files', action: :create_file
      post 'groups/:group_id/preview_html', action: :preview_html
      post 'group_categories/:group_category_id/groups', action: :create
      get 'groups/:group_id/activity_stream', action: :activity_stream, as: 'group_activity_stream'
      get 'groups/:group_id/activity_stream/summary', action: :activity_stream_summary, as: 'group_activity_stream_summary'
      put "groups/:group_id/followers/self", action: :follow
      delete "groups/:group_id/followers/self", action: :unfollow

      scope(controller: :group_memberships) do
        resources :memberships, path: "groups/:group_id/memberships", name_prefix: "group_", controller: :group_memberships, except: :show
        resources :users, path: "groups/:group_id/users", name_prefix: "group_", controller: :group_memberships, except: [:index, :show, :create]
      end

      get  'groups/:group_id/files', controller: :files, action: :api_index, as: 'group_files'
      get 'groups/:group_id/folders', controller: :folders, action: :list_all_folders, as: 'group_folders'
      post 'groups/:group_id/folders', controller: :folders, action: :create
      get 'groups/:group_id/folders/by_path/*full_path', controller: :folders, action: :resolve_path
      get 'groups/:group_id/folders/by_path', controller: :folders, action: :resolve_path
      get 'groups/:group_id/folders/:id', controller: :folders, action: :show, as: 'group_folder'
    end

    scope(controller: :developer_keys) do
      get 'developer_keys', action: :index
      get 'developer_keys/:id', action: :show
      delete 'developer_keys/:id', action: :destroy
      put 'developer_keys/:id', action: :update
      post 'developer_keys', action: :create
    end

    scope(controller: :search) do
      get 'search/rubrics', action: 'rubrics', as: 'search_rubrics'
      get 'search/recipients', action: 'recipients', as: 'search_recipients'
      get 'search/all_courses', action: 'all_courses', as: 'search_all_courses'
    end

    post 'files/:id/create_success', controller: :files, action: :api_create_success, as: 'files_create_success'
    get 'files/:id/create_success', controller: :files, action: :api_create_success

    scope(controller: :files) do
      post 'files/:id/create_success', action: :api_create_success
      get 'files/:id/create_success', action: :api_create_success
      # 'attachment' (rather than 'file') is used below so modules API can use polymorphic_url to generate an item API link
      get 'files/:id', action: :api_show, as: 'attachment'
      delete 'files/:id', action: :destroy
      put 'files/:id', action: :api_update
      get 'files/:id/:uuid/status', action: :api_file_status, as: 'file_status'
      get 'files/:id/public_url', action: :public_url
      %w(course group user).each do |context|
        get "#{context}s/:#{context}_id/files/quota", action: :api_quota
        get "#{context}s/:#{context}_id/files/:id", action: :api_show, as: "#{context}_attachment"
      end
    end

    scope(controller: :folders) do
      get 'folders/:id', action: :show
      get 'folders/:id/folders', action: :api_index, as: 'list_folders'
      get 'folders/:id/files', controller: :files, action: :api_index, as: 'list_files'
      delete 'folders/:id', action: :api_destroy
      put 'folders/:id', action: :update
      post 'folders/:folder_id/folders', action: :create, as: 'create_folder'
      post 'folders/:folder_id/files', action: :create_file
      post 'folders/:dest_folder_id/copy_file', action: :copy_file
      post 'folders/:dest_folder_id/copy_folder', action: :copy_folder
    end

    scope(controller: :favorites) do
      get "users/self/favorites/courses", action: :list_favorite_courses, as: :list_favorite_courses
      post "users/self/favorites/courses/:id", action: :add_favorite_course, as: :add_favorite_course
      delete "users/self/favorites/courses/:id", action: :remove_favorite_course, as: :remove_favorite_course
      delete "users/self/favorites/courses", action: :reset_course_favorites
    end

    scope(controller: :wiki_pages_api) do
      get "courses/:course_id/front_page", action: :show_front_page
      get "groups/:group_id/front_page", action: :show_front_page
      put "courses/:course_id/front_page", action: :update_front_page
      put "groups/:group_id/front_page", action: :update_front_page

      get "courses/:course_id/pages", action: :index, as: 'course_wiki_pages'
      get "groups/:group_id/pages", action: :index, as: 'group_wiki_pages'
      get "courses/:course_id/pages/:url", action: :show, as: 'course_wiki_page'
      get "groups/:group_id/pages/:url", action: :show, as: 'group_wiki_page'
      get "courses/:course_id/pages/:url/revisions", action: :revisions, as: 'course_wiki_page_revisions'
      get "groups/:group_id/pages/:url/revisions", action: :revisions, as: 'group_wiki_page_revisions'
      get "courses/:course_id/pages/:url/revisions/latest", action: :show_revision
      get "groups/:group_id/pages/:url/revisions/latest", action: :show_revision
      get "courses/:course_id/pages/:url/revisions/:revision_id", action: :show_revision
      get "groups/:group_id/pages/:url/revisions/:revision_id", action: :show_revision
      post "courses/:course_id/pages/:url/revisions/:revision_id", action: :revert
      post "groups/:group_id/pages/:url/revisions/:revision_id", action: :revert
      post "courses/:course_id/pages", action: :create
      post "groups/:group_id/pages", action: :create
      put "courses/:course_id/pages/:url", action: :update
      put "groups/:group_id/pages/:url", action: :update
      delete "courses/:course_id/pages/:url", action: :destroy
      delete "groups/:group_id/pages/:url", action: :destroy
    end

    scope(controller: :context_modules_api) do
      get "courses/:course_id/modules", action: :index, as: 'course_context_modules'
      get "courses/:course_id/modules/:id", action: :show, as: 'course_context_module'
      put "courses/:course_id/modules", action: :batch_update
      post "courses/:course_id/modules", action: :create, as: 'course_context_module_create'
      put "courses/:course_id/modules/:id", action: :update, as: 'course_context_module_update'
      delete "courses/:course_id/modules/:id", action: :destroy
      put "courses/:course_id/modules/:id/relock", action: :relock
    end

    scope(controller: :context_module_items_api) do
      get "courses/:course_id/modules/:module_id/items", action: :index, as: 'course_context_module_items'
      get "courses/:course_id/modules/:module_id/items/:id", action: :show, as: 'course_context_module_item'
      get "courses/:course_id/module_item_redirect/:id", action: :redirect, as: 'course_context_module_item_redirect'
      get "courses/:course_id/module_item_sequence", action: :item_sequence
      post "courses/:course_id/modules/:module_id/items", action: :create, as: 'course_context_module_items_create'
      put "courses/:course_id/modules/:module_id/items/:id", action: :update, as: 'course_context_module_item_update'
      delete "courses/:course_id/modules/:module_id/items/:id", action: :destroy
      post "courses/:course_id/modules/:module_id/items/:id/mark_read", action: :mark_item_read
    end

    scope(controller: 'quizzes/quiz_assignment_overrides') do
      get "courses/:course_id/quizzes/assignment_overrides", action: :index, as: 'course_quiz_assignment_overrides'
    end

    scope(controller: 'quizzes/quizzes_api') do
      get "courses/:course_id/quizzes", action: :index, as: 'course_quizzes'
      post "courses/:course_id/quizzes", action: :create, as: 'course_quiz_create'
      get "courses/:course_id/quizzes/:id", action: :show, as: 'course_quiz'
      put "courses/:course_id/quizzes/:id", action: :update, as: 'course_quiz_update'
      delete "courses/:course_id/quizzes/:id", action: :destroy, as: 'course_quiz_destroy'
      post "courses/:course_id/quizzes/:id/reorder", action: :reorder, as: 'course_quiz_reorder'
    end

    scope(controller: 'quizzes/quiz_submission_users') do
      get "courses/:course_id/quizzes/:id/submission_users", action: :index, as: 'course_quiz_submission_users'
      post "courses/:course_id/quizzes/:id/submission_users/message", action: :message, as: 'course_quiz_submission_users_message'
    end

    scope(controller: 'quizzes/quiz_groups') do
      post "courses/:course_id/quizzes/:quiz_id/groups", action: :create, as: 'course_quiz_group_create'
      put "courses/:course_id/quizzes/:quiz_id/groups/:id", action: :update, as: 'course_quiz_group_update'
      delete "courses/:course_id/quizzes/:quiz_id/groups/:id", action: :destroy, as: 'course_quiz_group_destroy'
      post "courses/:course_id/quizzes/:quiz_id/groups/:id/reorder", action: :reorder, as: 'course_quiz_group_reorder'
    end

    scope(controller: 'quizzes/quiz_questions') do
      get "courses/:course_id/quizzes/:quiz_id/questions", action: :index, as: 'course_quiz_questions'
      get "courses/:course_id/quizzes/:quiz_id/questions/:id", action: :show, as: 'course_quiz_question'
      post "courses/:course_id/quizzes/:quiz_id/questions", action: :create, as: 'course_quiz_question_create'
      put "courses/:course_id/quizzes/:quiz_id/questions/:id", action: :update, as: 'course_quiz_question_update'
      delete "courses/:course_id/quizzes/:quiz_id/questions/:id", action: :destroy, as: 'course_quiz_question_destroy'
    end

    scope(controller: 'quizzes/quiz_reports') do
      post "courses/:course_id/quizzes/:quiz_id/reports", action: :create, as: 'course_quiz_reports_create'
      delete "courses/:course_id/quizzes/:quiz_id/reports/:id", action: :abort, as: 'course_quiz_reports_abort'
      get "courses/:course_id/quizzes/:quiz_id/reports", action: :index, as: 'course_quiz_reports'
      get "courses/:course_id/quizzes/:quiz_id/reports/:id", action: :show, as: 'course_quiz_report'
    end

    scope(controller: 'quizzes/quiz_submission_files') do
      post 'courses/:course_id/quizzes/:quiz_id/submissions/self/files', action: :create, as: 'quiz_submission_files'
    end

    scope(controller: 'quizzes/quiz_submissions_api') do
      get 'courses/:course_id/quizzes/:quiz_id/submissions', action: :index, as: 'course_quiz_submissions'
      get 'courses/:course_id/quizzes/:quiz_id/submissions/:id', action: :show, as: 'course_quiz_submission'
      post 'courses/:course_id/quizzes/:quiz_id/submissions', action: :create, as: 'course_quiz_submission_create'
      put 'courses/:course_id/quizzes/:quiz_id/submissions/:id', action: :update, as: 'course_quiz_submission_update'
      post 'courses/:course_id/quizzes/:quiz_id/submissions/:id/complete', action: :complete, as: 'course_quiz_submission_complete'
    end

    scope(:controller => 'quizzes/outstanding_quiz_submissions') do
      get 'courses/:course_id/quizzes/:quiz_id/outstanding_quiz_submissions', :action => :index, :path_name => 'outstanding_quiz_submission_index'
      post 'courses/:course_id/quizzes/:quiz_id/outstanding_quiz_submissions', :action => :grade, :path_name => 'outstanding_quiz_submission_grade'
    end

    scope(controller: 'quizzes/quiz_extensions') do
      post 'courses/:course_id/quizzes/:quiz_id/extensions', action: :create, as: 'course_quiz_extensions_create'
    end

    scope(controller: 'quizzes/course_quiz_extensions') do
      post 'courses/:course_id/quiz_extensions', action: :create
    end

    scope(controller: "quizzes/quiz_submission_events_api") do
      get "courses/:course_id/quizzes/:quiz_id/submissions/:id/events", action: :index, as: 'course_quiz_submission_events'
      post "courses/:course_id/quizzes/:quiz_id/submissions/:id/events", action: :create, as: 'create_quiz_submission_events'
    end

    scope(controller: 'quizzes/quiz_submission_questions') do
      get '/quiz_submissions/:quiz_submission_id/questions', action: :index, as: 'quiz_submission_questions'
      post '/quiz_submissions/:quiz_submission_id/questions', action: :answer, as: 'quiz_submission_question_answer'
      get '/quiz_submissions/:quiz_submission_id/questions/:id', action: :show, as: 'quiz_submission_question'
      put '/quiz_submissions/:quiz_submission_id/questions/:id/flag', action: :flag, as: 'quiz_submission_question_flag'
      put '/quiz_submissions/:quiz_submission_id/questions/:id/unflag', action: :unflag, as: 'quiz_submission_question_unflag'
    end

    scope(controller: 'quizzes/quiz_ip_filters') do
      get 'courses/:course_id/quizzes/:quiz_id/ip_filters', action: :index, as: 'course_quiz_ip_filters'
    end

    scope(controller: 'quizzes/quiz_statistics') do
      get 'courses/:course_id/quizzes/:quiz_id/statistics', action: :index, as: 'course_quiz_statistics'
    end

    scope(controller: 'polling/polls') do
      get "polls", action: :index, as: 'polls'
      post "polls", action: :create, as: 'poll_create'
      get "polls/:id", action: :show, as: 'poll'
      put "polls/:id", action: :update, as: 'poll_update'
      delete "polls/:id", action: :destroy, as: 'poll_destroy'
    end

    scope(controller: 'polling/poll_choices') do
      get "polls/:poll_id/poll_choices", action: :index, as: 'poll_choices'
      post "polls/:poll_id/poll_choices", action: :create, as: 'poll_choices_create'
      get "polls/:poll_id/poll_choices/:id", action: :show, as: 'poll_choice'
      put "polls/:poll_id/poll_choices/:id", action: :update, as: 'poll_choice_update'
      delete "polls/:poll_id/poll_choices/:id", action: :destroy, as: 'poll_choice_destroy'
    end

    scope(controller: 'polling/poll_sessions') do
      get "polls/:poll_id/poll_sessions", action: :index, as: 'poll_sessions'
      post "polls/:poll_id/poll_sessions", action: :create, as: 'poll_sessions_create'
      get "polls/:poll_id/poll_sessions/:id", action: :show, as: 'poll_session'
      put "polls/:poll_id/poll_sessions/:id", action: :update, as: 'poll_session_update'
      delete "polls/:poll_id/poll_sessions/:id", action: :destroy, as: 'poll_session_destroy'
      get "polls/:poll_id/poll_sessions/:id/open", action: :open, as: 'poll_session_publish'
      get "polls/:poll_id/poll_sessions/:id/close", action: :close, as: 'poll_session_close'

      get "poll_sessions/opened", action: :opened, as: 'poll_sessions_opened'
      get "poll_sessions/closed", action: :closed, as: 'poll_sessions_closed'
    end

    scope(controller: 'polling/poll_submissions') do
      post "polls/:poll_id/poll_sessions/:poll_session_id/poll_submissions", action: :create, as: 'poll_submissions_create'
      get "polls/:poll_id/poll_sessions/:poll_session_id/poll_submissions/:id", action: :show, as: 'poll_submission'
    end

    scope(controller: 'live_assessments/assessments') do
      %w(course).each do |context|
        prefix = "#{context}s/:#{context}_id"
        get "#{prefix}/live_assessments", action: :index, as: "#{context}_live_assessments"
        post "#{prefix}/live_assessments", action: :create, as: "#{context}_live_assessment_create"
      end
    end

    scope(controller: 'live_assessments/results') do
      %w(course).each do |context|
        prefix = "#{context}s/:#{context}_id"
        get "#{prefix}/live_assessments/:assessment_id/results", action: :index, as: "#{context}_live_assessment_results"
        post "#{prefix}/live_assessments/:assessment_id/results", action: :create, as: "#{context}_live_assessment_result_create"
      end
    end

    scope(controller: :outcome_groups_api) do
      def og_routes(context)
        prefix = (context == "global" ? context : "#{context}s/:#{context}_id")
        unless context == "global"
          get "#{prefix}/outcome_groups", action: :index, as: "#{context}_outcome_groups"
          get "#{prefix}/outcome_group_links", action: :link_index, as: "#{context}_outcome_group_links"
        end
        get "#{prefix}/root_outcome_group", action: :redirect, as: "#{context}_redirect"
        get "#{prefix}/outcome_groups/account_chain", action: :account_chain, as: "#{context}_account_chain"
        get "#{prefix}/outcome_groups/:id", action: :show, as: "#{context}_outcome_group"
        put "#{prefix}/outcome_groups/:id", action: :update
        delete "#{prefix}/outcome_groups/:id", action: :destroy
        get "#{prefix}/outcome_groups/:id/outcomes", action: :outcomes, as: "#{context}_outcome_group_outcomes"
        get "#{prefix}/outcome_groups/:id/available_outcomes", action: :available_outcomes, as: "#{context}_outcome_group_available_outcomes"
        post "#{prefix}/outcome_groups/:id/outcomes", action: :link
        put "#{prefix}/outcome_groups/:id/outcomes/:outcome_id", action: :link, as: "#{context}_outcome_link"
        delete "#{prefix}/outcome_groups/:id/outcomes/:outcome_id", action: :unlink
        get "#{prefix}/outcome_groups/:id/subgroups", action: :subgroups, as: "#{context}_outcome_group_subgroups"
        post "#{prefix}/outcome_groups/:id/subgroups", action: :create
        post "#{prefix}/outcome_groups/:id/import", action: :import, as: "#{context}_outcome_group_import"
        post "#{prefix}/outcome_groups/:id/batch", action: :batch, as: "#{context}_outcome_group_batch"
      end

      og_routes('global')
      og_routes('account')
      og_routes('course')
    end

    scope(controller: :outcomes_api) do
      get "outcomes/:id", action: :show, as: "outcome"
      put "outcomes/:id", action: :update
      delete "outcomes/:id", action: :destroy
    end

    scope(controller: :outcome_results) do
      get 'courses/:course_id/outcome_rollups', action: :rollups, as: 'course_outcome_rollups'
      get 'courses/:course_id/outcome_results', action: :index, as: 'course_outcome_results'
    end

    scope(controller: :group_categories) do
      resources :group_categories, except: [:index, :create]
      get 'accounts/:account_id/group_categories', action: :index, as: 'account_group_categories'
      get 'courses/:course_id/group_categories', action: :index, as: 'course_group_categories'
      post 'accounts/:account_id/group_categories', action: :create
      post 'courses/:course_id/group_categories', action: :create
      get 'group_categories/:group_category_id/groups', action: :groups, as: 'group_category_groups'
      get 'group_categories/:group_category_id/users', action: :users, as: 'group_category_users'
      post 'group_categories/:group_category_id/assign_unassigned_members', action: 'assign_unassigned_members', as: 'group_category_assign_unassigned_members'
    end

    scope(controller: :progress) do
      get "progress/:id", action: :show, as: "progress"
    end

    scope(controller: :app_center) do
      ['course', 'account'].each do |context|
        prefix = "#{context}s/:#{context}_id/app_center"
        get  "#{prefix}/apps",                      action: :index,   as: "#{context}_app_center_apps"
        get  "#{prefix}/apps/:app_id/reviews",      action: :reviews, as: "#{context}_app_center_app_reviews"
        get  "#{prefix}/apps/:app_id/reviews/self", action: :review,  as: "#{context}_app_center_app_review"
        post "#{prefix}/apps/:app_id/reviews/self", action: :add_review
      end
    end

    scope(controller: :feature_flags) do
      ['course', 'account', 'user'].each do |context|
        prefix = "#{context}s/:#{context}_id/features"
        get "#{prefix}", action: :index, as: "#{context}_features"
        get "#{prefix}/enabled", action: :enabled_features, as: "#{context}_enabled_features"
        get "#{prefix}/flags/:feature", action: :show
        put "#{prefix}/flags/:feature", action: :update
        delete "#{prefix}/flags/:feature", action: :delete
      end
    end

    scope(controller: :conferences) do
      %w(course group).each do |context|
        prefix = "#{context}s/:#{context}_id/conferences"
        get prefix, action: :index, as: "#{context}_conferences"
      end
    end

    scope(controller: :custom_gradebook_columns_api) do
      prefix = "courses/:course_id/custom_gradebook_columns"
      get prefix, action: :index, as: "course_custom_gradebook_columns"
      post prefix, action: :create
      post "#{prefix}/reorder", action: :reorder,
        as: "custom_gradebook_columns_reorder"
      put "#{prefix}/:id", action: :update,
        as: "course_custom_gradebook_column"
      delete "#{prefix}/:id", action: :destroy
    end

    scope(controller: :custom_gradebook_column_data_api) do
      prefix = "courses/:course_id/custom_gradebook_columns/:id/data"
      get prefix, action: :index, as: "course_custom_gradebook_column_data"
      put "#{prefix}/:user_id", action: :update, as: "course_custom_gradebook_column_datum"
    end

    scope(controller: :content_exports_api) do
      %w(course group user).each do |context|
        context_prefix = "#{context.pluralize}/:#{context}_id"
        prefix = "#{context_prefix}/content_exports"
        get prefix, action: :index, as: "#{context}_content_exports"
        post prefix, action: :create
        get "#{prefix}/:id", action: :show
      end
      get "courses/:course_id/content_list", action: :content_list, as: "course_content_list"
    end

    scope(controller: :grading_standards_api) do
      post 'accounts/:account_id/grading_standards', action: :create
      post 'courses/:course_id/grading_standards', action: :create
    end

    get '/crocodoc_session', controller: 'crocodoc_sessions', action: 'show', as: :crocodoc_session
    get '/canvadoc_session', controller: 'canvadoc_sessions', action: 'show', as: :canvadoc_session

    scope(controller: :grading_periods) do
      %w(course account).each do |context|
        content_prefix = "#{context.pluralize}/:#{context}_id"
        prefix = "#{content_prefix}/grading_periods"
        get prefix, action: :index, as: "#{context}_grading_periods"
        get "#{prefix}/:id", action: :show, as: "#{context}_grading_period"
        post prefix, action: :create, as: "#{context}_grading_period_create"
        put "#{prefix}/:id", action: :update, as: "#{context}_grading_period_update"
        delete "#{prefix}/:id", action: :destroy, as: "#{context}_grading_period_destroy"
      end
    end

    scope(controller: :usage_rights) do
      %w(course group user).each do |context|
        content_prefix = "#{context.pluralize}/:#{context}_id"
        put "#{content_prefix}/usage_rights", action: :set_usage_rights
        delete "#{content_prefix}/usage_rights", action: :remove_usage_rights
        get "#{content_prefix}/content_licenses", action: :licenses
      end
    end

  end

  # this is not a "normal" api endpoint in the sense that it is not documented
  # or called directly, it's used as the redirect in the file upload process
  # for local files. it also doesn't use the normal oauth authentication
  # system, so we can't put it in the api uri namespace.
  post 'files_api' => 'files#api_create', as: :api_v1_files_create

  get 'login/oauth2/auth' => 'pseudonym_sessions#oauth2_auth', as: :oauth2_auth
  post 'login/oauth2/token' => 'pseudonym_sessions#oauth2_token', as: :oauth2_token
  get 'login/oauth2/confirm' => 'pseudonym_sessions#oauth2_confirm', as: :oauth2_auth_confirm
  post 'login/oauth2/accept' => 'pseudonym_sessions#oauth2_accept', as: :oauth2_auth_accept
  get 'login/oauth2/deny' => 'pseudonym_sessions#oauth2_deny', as: :oauth2_auth_deny
  delete 'login/oauth2/token' => 'pseudonym_sessions#oauth2_logout', as: :oauth2_logout

  ApiRouteSet.draw(self, "/api/lti/v1") do
    post "tools/:tool_id/grade_passback", controller: :lti_api, action: :grade_passback, as: "lti_grade_passback_api"
    post "tools/:tool_id/ext_grade_passback", controller: :lti_api, action: :legacy_grade_passback, as: "blti_legacy_grade_passback_api"
    post "xapi/:token", controller: :lti_api, action: :xapi_service, as: "lti_xapi"
    post "caliper/:token", controller: :lti_api, action: :caliper_service, as: "lti_caliper"
    post "logout_service/:token", controller: :lti_api, action: :logout_service, as: "lti_logout_service"
  end

  ApiRouteSet.draw(self, "/api/lti") do
    ['course', 'account'].each do |context|
      prefix = "#{context}s/:#{context}_id"
      get  "#{prefix}/tool_consumer_profile/:tool_consumer_profile_id", controller: 'lti/ims/tool_consumer_profile', action: 'show', as: "#{context}_tool_consumer_profile"
      post "#{prefix}/tool_proxy", controller: 'lti/ims/tool_proxy', action: :create, as: "create_#{context}_lti_tool_proxy"
    end
    #Tool Setting Services
    get "tool_settings/:tool_setting_id",  controller: 'lti/ims/tool_setting', action: :show, as: 'show_lti_tool_settings'
    put "tool_settings/:tool_setting_id",  controller: 'lti/ims/tool_setting', action: :update, as: 'update_lti_tool_settings'

    #Tool Proxy Services
    get  "tool_proxy/:tool_proxy_guid", controller: 'lti/ims/tool_proxy', action: :show, as: "show_lti_tool_proxy"

  end
end
