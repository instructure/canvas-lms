class Gradebook2Controller < ApplicationController
  before_filter :require_context
  add_crumb(proc { t('#crumbs.gradebook', "Gradebook")}) { |c| c.send :named_context_url, c.instance_variable_get("@context"), :context_grades_url }
  before_filter { |c| c.active_tab = "grades" }
  include Api::V1::CustomGradebookColumn

  def show
    if authorized_action(@context, @current_user, [:manage_grades, :view_all_grades])
      set_js_env
    end
  end

  def screenreader
    if @context.feature_enabled?(:screenreader_gradebook)
      if authorized_action(@context, @current_user, [:manage_grades, :view_all_grades])
        set_js_env
      end
    else
      redirect_to action: :show
    end
  end

  def set_js_env
    @gradebook_is_editable = @context.grants_right?(@current_user, session, :manage_grades)
    per_page = Setting.get('api_max_per_page', '50').to_i
    teacher_notes = @context.custom_gradebook_columns.not_deleted.where(:teacher_notes=> true).first
    js_env  :GRADEBOOK_OPTIONS => {
      :chunk_size => Setting.get('gradebook2.submissions_chunk_size', '35').to_i,
      :assignment_groups_url => api_v1_course_assignment_groups_url(@context, :include => [:assignments], :override_assignment_dates => "false"),
      :sections_url => api_v1_course_sections_url(@context),
      :students_url => api_v1_course_enrollments_url(@context, :include => [:avatar_url], :type => ['StudentEnrollment', 'StudentViewEnrollment'], :per_page => per_page),
      :students_url_with_concluded_enrollments => api_v1_course_enrollments_url(@context, :include => [:avatar_url], :type => ['StudentEnrollment', 'StudentViewEnrollment'], :state => ['active', 'invited', 'completed'], :per_page => per_page),
      :submissions_url => api_v1_course_student_submissions_url(@context, :grouped => '1'),
      :change_grade_url => api_v1_course_assignment_submission_url(@context, ":assignment", ":submission"),
      :context_url => named_context_url(@context, :context_url),
      :download_assignment_submissions_url => named_context_url(@context, :context_assignment_submissions_url, "{{ assignment_id }}", :zip => 1),
      :re_upload_submissions_url => named_context_url(@context, :submissions_upload_context_gradebook_url, "{{ assignment_id }}"),
      :context_id => @context.id,
      :context_code => @context.asset_string,
      :group_weighting_scheme => @context.group_weighting_scheme,
      :grading_standard =>  @context.grading_standard_enabled? && (@context.grading_standard.try(:data) || GradingStandard.default_grading_standard),
      :course_is_concluded => @context.completed?,
      :gradebook_is_editable => @gradebook_is_editable,
      :setting_update_url => api_v1_course_settings_url(@context),
      :show_total_grade_as_points => @context.settings[:show_total_grade_as_points],
      :publish_to_sis_enabled => @context.allows_grade_publishing_by(@current_user) && @gradebook_is_editable,
      :publish_to_sis_url => context_url(@context, :context_details_url, :anchor => 'tab-grade-publishing'),
      :speed_grader_enabled => @context.allows_speed_grader?,
      :draft_state_enabled => @context.feature_enabled?(:draft_state),
      :outcome_gradebook_enabled => @context.feature_enabled?(:outcome_gradebook),
      :custom_columns_url => api_v1_course_custom_gradebook_columns_url(@context),
      :custom_column_url => api_v1_course_custom_gradebook_column_url(@context, ":id"),
      :custom_column_data_url => api_v1_course_custom_gradebook_column_data_url(@context, ":id", per_page: per_page),
      :custom_column_datum_url => api_v1_course_custom_gradebook_column_datum_url(@context, ":id", ":user_id"),
      :reorder_custom_columns_url => api_v1_custom_gradebook_columns_reorder_url(@context),
      :teacher_notes => teacher_notes && custom_gradebook_column_json(teacher_notes, @current_user, session),
      :change_gradebook_version_url => context_url(@context, :change_gradebook_version_context_gradebook_url, :version => 2)
    }
  end
end
