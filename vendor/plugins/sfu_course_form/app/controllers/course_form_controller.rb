require Pathname(File.dirname(__FILE__)) + "../../../sfu_api/app/model/sfu/sfu"

class CourseFormController < ApplicationController

  before_filter :require_user

  def new
    @user = User.find(@current_user.id)
    @sfuid = @user.pseudonym.unique_id
    @sfuid.slice! "@sfu.ca"
    @course_list = Array.new
    @current_term = current_term
    @terms = [@current_term] + future_terms
    # only show current term plus next 2 terms (up to 3 non-nil terms in total)
    @term_options = @terms.compact.take(3).map { |term| [term.name, term.sis_source_id] }
    roles = SFU::User.roles @sfuid
    @is_student = (roles & %w(undergrad grad fic)).any?
    # deny access unless user has any of the following roles
    unless (roles & %w(staff faculty f_faculty grad other)).any?
      flash[:error] = "You don't have permission to access that page"
      redirect_to dashboard_url
    end
  end

  def create
    req_user = User.find(@current_user.id).pseudonym.unique_id
    selected_courses = []
    account_id = Account.find_by_name("Simon Fraser University").id
    teacher_username = params[:username]
    teacher2_username = params[:enroll_me]
    teacher_sis_user_id = sis_user_id(teacher_username, account_id)
    teacher2_sis_user_id = sis_user_id(teacher2_username, account_id) unless teacher2_username.nil?
    teacher2_role = sanitize_role(params[:enroll_me_as])
    cross_list = params[:cross_list]

    params.each do |key, value|
      if key.to_s.starts_with? "selected_course"
        selected_courses.push value
      end
    end

    begin
      course_csv, section_csv, enrollment_csv = SFU::CourseForm::CSVBuilder.build(req_user, selected_courses.compact.uniq, account_id, teacher_username, teacher_sis_user_id, teacher2_sis_user_id, teacher2_role, cross_list)

      logger.info "[SFU Course Form] course_csv: #{course_csv.inspect}"
      SFU::Canvas.sis_import course_csv

      logger.info "[SFU Course Form] section_csv: #{section_csv.inspect}"
      SFU::Canvas.sis_import section_csv

      logger.info "[SFU Course Form] enrollment_csv: #{enrollment_csv.inspect}"
      SFU::Canvas.sis_import enrollment_csv

      # give some time for the delayed_jobs to process the import
      sleep 5
      render :json => {
          :success => true,
          :message => 'Course request submitted successfully.'
      }
    rescue Exception => e
      render :json => {
          :success => false,
          :message => e.message
      }
      return
    end

  end

  def sis_user_id(username, account_id)
    user = Pseudonym.find_by_unique_id_and_account_id(username, account_id)
    user.sis_user_id unless user.nil?
  end

  def sanitize_role(role)
    # limit role to teacher (default), TA, and designer
    %w(teacher ta designer).include?(role) ? role : 'teacher'
  end

  def current_term
    EnrollmentTerm.find(:all, :conditions => ["workflow_state = 'active' AND (:date BETWEEN start_at AND end_at)", {:date => DateTime.now}]).first
  end

  def future_terms
    EnrollmentTerm.find(:all, :conditions => ["workflow_state = 'active' AND (:date <= start_at)", {:date => DateTime.now}], :order => 'sis_source_id')
  end

end
