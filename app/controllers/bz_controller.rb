# This holds BZ custom endpoints for updating our
# custom data.

require 'google/api_client'
require 'google/api_client/auth/storage'
require 'google/api_client/auth/storages/file_store'

require 'csv'

require 'bz_grading'

class BzController < ApplicationController

  # magic field dump / for cohorts uses an access token instead
  # and courses_for_email is unauthenticated since it isn't really sensitive
  before_filter :require_user, :except => [:magic_field_dump, :courses_for_email, :magic_fields_for_cohort, :tas_for_course]
  skip_before_filter :verify_authenticity_token, :only => [:last_user_url, :set_user_retained_data, :delete_user, :user_retained_data_batch]

  # this is meant to be used for requests from external services like LL kits
  # to see what courses the user is in. SSO just gives email, and server side, there
  # isn't an authentication token, so we just want to give back numbers for the email
  # address. Since course IDs aren't really sensitive, I am just letting it go unauthenticated
  # (worst this could reveal is that email address X is associated with Braven program Y... just
  # hitting "forgot password" with that email can already reveal that anyway, so no new hole.)
  #
  # I am also not using an access token like with the api since that actually opens the attack
  # surface - they have access to a LOT more if something goes wrong.

  # Input: email=something
  # Output: while(1);{"course_id":[list,of,course,ids]}
  # course ids may be repeated.
  def courses_for_email
    email = params[:email]

    result = {}
    result["course_ids"] = []

    ul = UserList.new(email)
    ul.users.each do |u|
      u.enrollments.active.each do |e|
        result["course_ids"] << e.course_id
      end
    end

    render :json => result
  end

  # give it a course_id
  def tas_for_course
    access_token = AccessToken.authenticate(params[:access_token])
    if access_token.nil?
      render :json => "Access denied"
      return
    end

    requesting_user = access_token.user
    # we should prolly allow designer accounts to access too, but
    # for now i just want to use the admin access token for myself
    if requesting_user.id != 1
      render :json => "Not admin"
      return
    end

    course = Course.find(params[:course_id])

    result = {}
    result["tas"] = []
    course.ta_enrollments.each do |enrollment|
      obj = {}
      obj["id"] = enrollment.user.id
      obj["name"] = enrollment.user.name
      obj["email"] = enrollment.user.email
      result["tas"] << obj
    end

    render :json => result
  end

  # given an email and a list of magic field names,
  # it will return the responses for each magic field
  # requested for the cohort under that email.
  #
  # You can optionally pass a course_id too.
  #
  # email=whatever&fields[]=something&fields[]=more
  # etc. returns; { "answers" : { "field": { "student":"answer","student2":"answer2" }, "field2"....etc } }
  def magic_fields_for_cohort

    access_token = AccessToken.authenticate(params[:access_token])
    if access_token.nil?
      render :json => "Access denied"
      return
    end

    requesting_user = access_token.user
    # we should prolly allow designer accounts to access too, but
    # for now i just want to use the admin access token for myself
    if requesting_user.id != 1
      render :json => "Not admin"
      return
    end


    email = params[:email]
    enrollment = nil
    ul = UserList.new(email)
    ul.users.each do |user|
      if params[:course_id]
        user.ta_enrollments.each do |tae|
          if tae.course_id.to_s == params[:course_id].to_s
            enrollment = tae
          end
        end
      else
        enrollment = user.ta_enrollments.first
      end
      break unless enrollment.nil?
    end

    result = {}
    result["answers"] = {}

    if enrollment
      enrollment.course_section.students.each do |student|
        params[:fields].each do |name|
          if result["answers"][name].nil?
            result["answers"][name] = {}
          end
          rd = RetainedData.get_for_course(enrollment.course_id, student.id, name)
          value = rd.nil? ? "" : rd.value
          result["answers"][name][student.name] = value
        end
      end
    end

    render :json => result
  end

  def champion_connect_redirect
    redirect_to BeyondZConfiguration.join_url + "connect"
  end

  def cohort_info_upload
    @course_id = params[:course_id]
    # view render
  end

  def my_cohort
    # view render
  end

  def do_cohort_info_upload
    if params[:import].nil?
      flash[:message] = 'Please upload a csv file'
      redirect_to cohort_info_upload_path(course_id: params[:course_id])
      return
    end

    file = CSV.parse(params[:import][:csv].read)

    file.each_with_index do |row, index|
      next if index == 0 # skip the header row

      next if row[0].blank?

      row = row.map(&:strip)

      existing = CohortInfo.where(:course_id => params[:import][:course_id], :section_name => row[0])
      obj = nil
      if existing.any?
        obj = existing.first
      else
        obj = CohortInfo.new
      end

      obj.course_id = params[:import][:course_id]
      obj.section_name = row[0]
      obj.lc_name = row[1]
      obj.lc_email = row[2]
      obj.lc_phone = row[3]
      obj.ta_name = row[4]
      obj.ta_email = row[5]
      obj.ta_phone = row[6]
      obj.ta_office = row[7]
      obj.ll_times = row[8]
      obj.ll_location = row[9]

      obj.save
    end

    # enable the display now too
    course = Course.find(params[:import][:course_id])
    course.enable_my_info = true
    course.save

    flash[:message] = 'Data saved!'
    redirect_to cohort_info_upload_path(course_id: params[:import][:course_id])
  end

  def cohort_info_download
    course_id = params[:course_id]

    course = Course.find(course_id)
    sections = {}
    course.course_sections.each do |s|
      sections[s.name] = false
    end

    csv = CSV.generate do |csv|
      csv << ["Section Name", "LC Name", "LC Email", "LC Phone", "TA Name", "TA Email", "TA Phone", "TA Office Hours/Location", "LL Times", "LL Location"]

      CohortInfo.where(:course_id => course_id).each do |ci|
        sections[ci.section_name] = true
        csv << [ci.section_name, ci.lc_name, ci.lc_email, ci.lc_phone, ci.ta_name, ci.ta_email, ci.ta_phone, ci.ta_office, ci.ll_times, ci.ll_location]
      end

      sections.each do |name, done|
        if !done
          lc = course.course_sections.where(:name => name).first.tas.first
          if lc.nil?
            csv << [name]
          else
            csv << [name, lc.name, lc.email]
          end
        end
      end
    end

    respond_to do |format|
      format.csv { render text: csv }
    end
  end

  def grade_details
    module_item_id = params[:module_item_id]
    @module_item_id = module_item_id

    bzg = BZGrading.new
    @course = bzg.get_context_module(module_item_id).course

    @is_staff = @course.grants_right?(@current_user, session, :view_all_grades)

    user = params[:user_id].nil? ? @current_user : User.find(params[:user_id])
    @user_id = user.id

    if user.id != @current_user.id && !@is_staff
      raise "permission denied"
    end

    @response_object = bzg.calculate_user_module_score(module_item_id, user)
    i = 0
    @document = nil
    bzg.module_unique_magic_fields(module_item_id) do |umf|
      if i == 0
        @document = umf.document
      end
      umf["data-bz-grade-info"] = @response_object["audit_trace"][i].to_json
      i += 1
    end
  end

  def grades_download
    download = BzController::ExportGrades.new(@current_user.id, params)
    Delayed::Job.enqueue(download, max_attempts: 1)
  end

  # When in speed grader and there's an assignment with BOTH magic fields and file upload,
  # Canvas prefers the file upload. It won't even submit the magic field info if the user
  # uploads the file, nor will it allow the grader to see it.
  #
  # This page allows us to link to the assignment definition with a specific user's magic
  # field entry for use from the grader. It is meant to be iframed in there for TAs.
  def assignment_with_magic_fields
    course_id = params[:course]
    assignment_id = params[:assignment]
    student_id = params[:student] || @current_user.id

    @assignment = Assignment.find(assignment_id)
    @context = Course.find(course_id)
    if @assignment.rubric_association || can_do(@context, @current_user, :manage_grades) || student_id == @current_user.id
      @assignment_html = @assignment.description

      # this is basically a port of the getInnerHtmlWithMagicFieldsReplaced function
      # from bz_support.js. Just doing it server side for 1) speed and 2) viewing another
      # user's data, with proper permission checking
      doc = Nokogiri::HTML(@assignment_html)

      cohort = current_cohort(User.find(student_id), @context)

      doc.css(".duplicate-for-each-cohort-member").each do |o|

        html = o.inner_html

        newHtml = ''

        cohort.each do |id, name|
          replacedHtml = html.gsub("{ID}", id.to_s);
          replacedHtml = replacedHtml.gsub("{COURSE_ID}", @context.id.to_s);
          replacedHtml = replacedHtml.gsub("{NAME}", name);

          newHtml += replacedHtml;
        end

        o.inner_html = newHtml

        o['class'] = 'duplicate-for-each-cohort-member already-duplicated'
      end

      doc.css('[data-bz-retained]').each do |o|
        result = RetainedData.where(:user_id => student_id, :name => o["data-bz-retained"])
        value = ''
        value = result.first.value unless result.empty?

        if o.name == "TEXTAREA"
          n = doc.create_element 'div'
          n.content = value
        elsif o.name == "INPUT" && o.attr('type') == 'checkbox'
          n = doc.create_element 'span'
          n.inner_html = value == 'yes' ? '[X]' : '[ ]'
        elsif o.name == "INPUT" && o.attr('type') == 'radio'
          n = doc.create_element 'span'
          n.inner_html = value == 'yes' ? '[O]' : '[ ]'
        elsif value =~ /\A#{URI::regexp(['http', 'https'])}\z/
          # it is a link, limit the length so it doesn't break formats
          n = doc.create_element 'a'
          n['href'] = value
          if value.length > 60
            n.content = value[0 .. 24] + " ... " + value[value.length - 24 .. -1]
          else
            n.content = value
          end
        else
          n = doc.create_element 'span'
          n.content = value
        end

        n['class'] = "bz-retained-field-replaced"

        o.replace n

      end

      @assignment_html = "<div class=\"bz-magic-field-submission\">" + doc.to_xhtml + "</div>";

      @permission = true
    else
      @permission = false
    end
  end

  def load_wiki_pages
    names = params[:names]
    course_id = params[:course_id]

    all_pages = Course.find(course_id).wiki_pages.active

    result = {}
    names.each do |name|
      page = all_pages.where(:title => name)
      if page.any?
        result[name] = page.first.body
      end
    end

    render :json => result
  end

  def user_linkedin_url
    result = {}
    result['linkedin_url'] = ''

    @current_user.user_services.each do |service|
      if service.service == "linked_in"
        result['linkedin_url'] = service.service_user_link
        break
      end
    end

    render :json => result
  end

  def accessibility_mapper
    @items = []
    WikiPage.all.each do |page|
      doc = Nokogiri::HTML(page.body)
      doc.css('img:not(.bz-magic-viewer)').each do |img|
        if img.attributes["alt"].nil?
          @items << { :page => page, :path => img.css_path, :html => img.to_xhtml, :problem => 'Missing alt text', :fix => 'tag' }
        elsif img.attributes["alt"].value == ""
          @items << { :page => page, :path => img.css_path, :html => img.to_xhtml, :problem => 'Empty alt text', :fix => 'tag' }
        elsif img.attributes["alt"].value.ends_with?(".png")
          @items << { :page => page, :path => img.css_path, :html => img.to_xhtml, :problem => 'Poor alt text', :fix => 'tag' }
        elsif img.attributes["alt"].value.ends_with?(".jpg")
          @items << { :page => page, :path => img.css_path, :html => img.to_xhtml, :problem => 'Poor alt text', :fix => 'tag' }
        elsif img.attributes["alt"].value.ends_with?(".svg")
          @items << { :page => page, :path => img.css_path, :html => img.to_xhtml, :problem => 'Poor alt text', :fix => 'tag' }
        elsif img.attributes["alt"].value.ends_with?(".gif")
          @items << { :page => page, :path => img.css_path, :html => img.to_xhtml, :problem => 'Poor alt text', :fix => 'tag' }
        end
      end
      doc.css('iframe[src*="vimeo"]:not([data-bz-accessibility-ok])').each do |img|
        orig = img.to_xhtml
        img.set_attribute('data-bz-accessibility-ok', 'yes')
        repl = img.to_xhtml
        @items << { :page => page, :path => img.css_path, :html => orig, :problem => 'Ensure video has CC', :fix => 'button', :fix_html => repl }
      end
      doc.css('iframe[src*="youtu"]:not([data-bz-accessibility-ok])').each do |img|
        orig = img.to_xhtml
        img.set_attribute('data-bz-accessibility-ok', 'yes')
        repl = img.to_xhtml
        @items << { :page => page, :path => img.css_path, :html => orig, :problem => 'Ensure video has CC', :fix => 'button', :fix_html => repl }
      end
    end
  end

  def save_html_changes
    # FIXME: require admin user login properly
    if @current_user.email != 'admin@beyondz.org'
      raise "unauthorized"
    end

    page = WikiPage.find(params[:page_id])
    doc = Nokogiri::HTML(page.body)
    part = doc.css(params[:path])[0]
    raise "wtf" if params[:original_html] != part.to_xhtml
    part.replace(params[:new_html])
    page.body = doc.to_s
    page.save

    redirect_to bz_accessibility_mapper_path
  end

  def full_module_view
    @course_id = params[:course_id]
    module_sequence = params[:module_sequence]
    @module_sequence = module_sequence
    items = nil
    if module_sequence.nil?
      # view the entire course
      items = []
      Course.find(@course_id.to_i).context_modules.active.each do |ms|
        items += ms.content_tags_visible_to(@current_user)
      end
    else
      # view just one module inside a course
      items = Course.find(@course_id.to_i).context_modules.active[module_sequence.to_i].content_tags_visible_to(@current_user)
    end
    @pages = []
    items.each do |item|
      next if !item.published?
      # what about assignments?
      if item.content_type == "WikiPage"
        wp = WikiPage.find(item.content_id)
        @pages << wp
      end
    end
  end

  def magic_field_dump
    access_token = AccessToken.authenticate(params[:access_token])
    if access_token.nil?
      render :json => "Access denied"
      return
    end

    requesting_user = access_token.user
    # we should prolly allow designer accounts to access too, but
    # for now i just want to use the admin access token for myself
    if requesting_user.id != 1
      render :json => "Not admin"
      return
    end

    result = RetainedData.where("updated_at > to_timestamp(?)", params[:since])
    data = []
    result.all.each do |res|
      obj = {}
      obj["created_at"] = res.created_at
      obj["updated_at"] = res.updated_at
      obj["name"] = res.name
      obj["value"] = res.value
      obj["path"] = res.path
      obj["user_id"] = res.user_id
      data << obj
    end
    render :json => data
  end

  def user_retained_data
    Rails.logger.debug("### user_retained_data - all params = #{params.inspect}")
    result = RetainedData.where(:user_id => @current_user.id, :name => params[:name])
    data = ''
    if !result.empty?
      data = result.first.value
    end
    render :json => data
  end

  def user_retained_data_batch
    data = {}
    if params[:names]
      params[:names].each do |name|
        next if data[name]
        result = RetainedData.where(:user_id => @current_user.id, :name => name)
        data[name] = result.empty? ? '' : result.first.value
      end
    end
    render :json => data
  end


  def set_user_retained_data
    response_object = {}
    response_object["points_given"] = false
    response_object["points_reason"] = "N/A"

    Rails.logger.debug("### set_user_retained_data - all params = #{params.inspect} for user = #{@current_user.name}")
    result = RetainedData.where(:user_id => @current_user.id, :name => params[:name])
    data = nil
    was_new = false
    # if a student hacks this to set optional = true... they just lose out on their own points
    # so i don't mind it being passed to us from the client.
    was_optional = params[:optional]
    field_type = params[:type]
    answer = params[:answer]
    weight = params[:weight].blank? ? 1 : params[:weight].to_i
    partial_credit_mode = params[:partial_credit]
    if result.empty?
      data = RetainedData.new()
      data.user_id = @current_user.id
      data.path = request.referrer ? request.referrer[0 .. 220] : '' # trim off unnecessary detail so it fits in db
      data.name = params[:name]
      was_new = true
    else
      data = result.first
    end

    data.value = params[:value]
    data.save

    # now that the user's work is safely saved, we will go back and do addon work
    # like micrograding

    if was_new && !was_optional && (field_type != 'checkbox' || !answer.nil?) # Checkboxes are optional by nature unless there is an answer
      bzg = BZGrading.new

      course_id = request.referrer[/\/courses\/(\d+)\//, 1]
      module_item_id = request.referrer[/module_item_id=(\d+)/, 1]
      if module_item_id.nil?
        # They may have accessed the page from a direct link which didn't provide the module_item_id parameter,
        # so look it up.
        name = request.referrer[/\/courses\/\d+\/pages\/([a-zA-Z0-9_\-]{2,})/, 1]
        Rails.logger.debug("### set_user_retained_data - parsed the WikiPage name = #{name}")
        pages = WikiPage.where(:url => name)
        Rails.logger.debug("### set_user_retained_data - found WikiPages = #{pages.inspect}")
        tag = nil
        pages.each do |page| # Don't know which WikiPage is from this course, need to lookup the ContentTag for each to find the association
          tag = ContentTag.where(:content_id => page.id, :context_id => course_id, :context_type => 'Course', :content_type => 'WikiPage').first
          if !tag.nil?
            module_item_id = tag.id
            Rails.logger.debug("### set_user_retained_data - found ContentTag for this course_id = #{course_id}, tag = #{tag.inspect} and set the module_item_id = #{module_item_id} for the page #{request.referrer}")
            break
          end
        end
      end
      Rails.logger.debug("### set_user_retained_data - course_id = #{course_id}, module_item_id = #{module_item_id}")
      course = nil
      is_student = false
      if course_id
        course = Course.find(course_id)
        is_student = course.student_enrollments.active.where(:user_id => @current_user.id).any?
      end
      if is_student && module_item_id
        # assuming course is set from above

        tag = ContentTag.find(module_item_id)
        context_module = tag.context_module

        # counting the total number of magic fields is a really slow operation since it needs to
        # scan the whole module. Thus, it is aggressively cached. Major changes to a course in
        # the middle of a term can thus throw off scores (since the existing points don't adapt to
        # the step) and changes (since the cache won't instantly update - it will update in a week,
        # so probably next monday).
        #
        # However, given that we can just round up the points at the end of the semester and most the
        # steps will be fractional points, and most the content will be written ahead of time, this
        # shouldn't be a real problem.
        # old one was magic_field_count, now it is magic_field_counts -- new cache returns an array for more detail
        magic_field_counts = Rails.cache.fetch("magic_field_counts_for_course_#{course_id}_#{context_module.id}", :expires_in => 1.day) do
          internal_bzg = BZGrading.new
          internal_bzg.get_magic_field_weight_count(module_item_id)
        end
        Rails.logger.debug("### set_user_retained_data - magic_field_counts(total, supposed_to_be_blank) = #{magic_field_counts}")

        magic_field_total_weight = magic_field_counts[0]
        graded_checkboxes_that_are_supposed_to_be_empty_weight = magic_field_counts[1]

        participation_assignment = bzg.get_participation_assignment(course, context_module)
        if !participation_assignment.nil?
          internal_response = bzg.get_value_of_user_answer(params[:name], magic_field_counts, @current_user, participation_assignment, params[:value], DateTime.now, weight, answer, field_type, partial_credit_mode)

          response_object["points_given"] = internal_response["points_given"]
          response_object["points_amount"] = internal_response["points_amount"]
          response_object["points_reason"] = internal_response["points_reason"]
          response_object["points_possible"] = internal_response["points_possible"]

          if internal_response["points_changed"]
            score_set_to = bzg.add_to_user_grade(participation_assignment, @current_user, graded_checkboxes_that_are_supposed_to_be_empty_weight, internal_response["points_possible"], internal_response["points_amount"])

            response_object["score_set_to"] = score_set_to
          elsif internal_response["points_reason"] == "past_due"
            Rails.logger.warn("### set_user_retained_data - for user #{@current_user.name} the magic field #{params[:name]} was completed on #{DateTime.now} which is after the due date")

            # if they haven't yet made a submission (no participation) and try to past due,
            # go ahead and make it an automatic 0. This allows TAs to see it was submitted
            # late so they can give an answer, and gives consistent non-null values in our
            # grade analysis exports.
            submission = participation_assignment.find_or_create_submission(@current_user)
            if submission.grade.nil?
              response_object["score_set_to"] = 0
              submission.with_lock do
                participation_assignment.grade_student(@current_user, {:grade => 0, :suppress_notification => true })
              end
            end
          end
        end
      elsif is_student
        response_object["points_reason"] = "missing_param"
        Rails.logger.error("### set_user_retained_data - missing either course_id = #{course_id} or module_item_id = #{module_item_id}. Can't update the Course Participation grade without that! user = #{@current_user.inspect}")
      end
    end
    render :json => response_object
  end

  def retained_data_stats
    @aggregate_result = ActiveRecord::Base.connection.execute("
      SELECT
        count(*) AS cnt,
        value
      FROM
        retained_data
      WHERE
        name = #{ActiveRecord::Base.connection.quote(params[:name])}
      GROUP BY
        value
      ORDER BY
        cnt DESC
    ")

    individual_responses = ActiveRecord::Base.connection.execute("
      SELECT
        user_id,
        value,
        path
      FROM
        retained_data
      WHERE
        name = #{ActiveRecord::Base.connection.quote(params[:name])}
      ORDER BY
        value
    ")

    @individual_responses = []

    individual_responses.each do |response|
      # this is WAY less efficient than doing a join but
      # idk how the model pulls this so i'm just letting
      # ruby do it.
      u = User.find(response["user_id"])
      r = {}
      r["value"] = response["value"]
      r["path"] = response["path"]
      r["name"] = u.name
      r["email"] = u.email
      @individual_responses.push(r)
    end

    @name = params[:name]
  end

  def retained_data_export
    course = Course.find(params[:course])
    all_fields = {}
    items = []
    course.enrollments.each do |enrollment|
      u = User.find(enrollment.user_id)
      item = {}
      item["Name"] = u.name
      item["Email"] = u.email

      RetainedData.where(:user_id => u.id).each do |rd|
        next if params[:type] == 'magic' && rd.name.starts_with?('instant-survey-')
        next if params[:type] == 'survey' && !rd.name.starts_with?('instant-survey-')

        # only keep generic or fields set specifically on this course...
        # the problem is if the same user is in two courses with the content bank,
        # it will only export the most recent ones set.
        next if !rd.path.blank? && rd.path.match("courses/#{course.id}").nil?

        item[rd.name] = rd.value
        all_fields[rd.name] = rd.name
      end

      items.push(item)
    end

    csv_result = CSV.generate do |csv|
      header = []
      header << "Name"
      header << "Email"
      all_fields.each do |k, v|
        if v.starts_with?("instant-survey-")
          page = WikiPage.find(v["instant-survey-".length ... v.length].to_i)
          # I can't believe that url isn't just a public method but nope
          # gotta construct myself
          header << "http://#{HostUrl.context_host(context)}/#{page.context.class.to_s.downcase.pluralize}/#{page.context.id}/pages/#{page.url}"
        else
          header << v
        end
      end
      csv << header

      items.each do |item|
        row = []
        row << item["Name"]
        row << item["Email"]
        all_fields.each do |k, v|
          row << item[v]
        end

        csv << row
      end
    end

    respond_to do |format|
      format.csv { render text: csv_result }
    end
  end

  def linked_in_export_oauth_success
    Rails.logger.debug("### linked_in_export_oauth_success - begin oauth_token = #{params[:oauth_token].inspect}.")
    oauth_request = nil
    if params[:oauth_token]
      oauth_request = OauthRequest.where(token: params[:oauth_token], service: params[:service]).first
    end
    if !oauth_request
      Rails.logger.error("OAuth Request failed. Couldn't find valid request")
    elsif request.host_with_port != oauth_request.original_host_with_port
      url = url_for request.parameters.merge(:host => oauth_request.original_host_with_port, :only_path => false)
      redirect_to url
    else
      begin
        linked_in_oauth_success(oauth_request, session)
      rescue => e
        Canvas::Errors.capture_exception(:oauth, e)
        Rails.logger.error("LinkedIn authorization failed for oauth_request = #{oauth_request.inspect}. Please try again")
      end
    end
  end

  # Renders a view to authorize access to LinkedIn regardless of what course you are enrolled in.
  def linked_in_auth
    @host_url = "#{request.protocol}#{request.host_with_port}"
  end

  def linked_in_export
    # renders a view to fetch the email address
    @email = @current_user.email
  end

  def do_linked_in_export
    work = BzController::ExportWork.new(params[:email])
    Delayed::Job.enqueue(work, max_attempts: 1)
  end

  # (private)
  
  class ExportGrades
    def initialize(user_id, params)
      @user = User.find(user_id)
      @params = params
    end
    
    def perform
      csv = Export::GradeDownload.csv(@user, @params)
      Mailer.bz_message(@user.email, "Export Success: Course #{@params[:course_id]}", "Attached is your export data", "grades_download.csv" => csv).deliver
      
      csv
    end

    def on_permanent_failure(error)
      er_id = Canvas::Errors.capture_exception("BzController::ExportGrades", error)[:error_report]
      # email us?
      Mailer.debug_message("Export FAIL", error.to_s).deliver
      Mailer.bz_message(@user.email, "Export Failed :(", "Your grades download export didn't work. The tech team was also emailed to look into why.")
    end
  end
  
  class ExportWork # < Delayed::PerformableMethod
    def initialize(email)
      @email = email
    end

    def perform
      csv = linked_in_export_guts
      Mailer.bz_message(@email, "Export Success", "Attached is your export data", "linkedin.csv" => csv).deliver
      # super
      csv
    end

    def on_permanent_failure(error)
      er_id = Canvas::Errors.capture_exception("BzController::ExportWork", error)[:error_report]
      # email us?
      Mailer.debug_message("Export FAIL", error.to_s).deliver
      Mailer.bz_message(@email, "Export Failed :(", "Your linked in export didn't work. The tech team was also emailed to look into why.")
    end

    def linked_in_export_guts
      Rails.logger.debug("### linkedin_data_export - begin")

      connection = LinkedIn::Connection.new

      items = []
      User.all.each do |u|
        item = {}
        item["braven-id"] = u.id

        u.user_services.each do |service|
          if service.service == "linked_in"
            Rails.logger.debug("### Found registered LinkedIn service for #{u.name}: #{service.service_user_link}")

            # See: https://developer.linkedin.com/docs/fields/full-profile
            fetched_li_data = true
            request = connection.get_request("/v1/people/~:(id,first-name,last-name,maiden-name,email-address,location,industry,num-connections,num-connections-capped,summary,specialties,public-profile-url,last-modified-timestamp,associations,interests,publications,patents,languages,skills,certifications,educations,courses,volunteer,three-current-positions,three-past-positions,num-recommenders,recommendations-received,following,job-bookmarks,honors-awards)?format=json", service.token)

            # NOTE: The 'suggestions' field was causing this error, so we're not fetching it:
            # {"errorCode"=>0, "message"=>"Internal API server error", "requestId"=>"Y4175L15PK", "status"=>500, "timestamp"=>1490298963387}
            # Also, I decided not to fetch picture-urls::(original)

            info = JSON.parse(request.body)

            if info["errorCode"] == 0
              fetched_li_data = false
              Rails.logger.error("### Error exporting LinkedIn data for user = #{u.name} - #{u.email}.  Details: #{info.inspect}")
              # TODO: if "message"=>"Unable to verify access token" we should unregister the user.  I reproduced this by registering a second
              # account with the same LinkedIn account.  It invalidated the first.

              if info["message"] == "Internal API server error" # For certain LinkedIn accounts, requesting the job-bookmarks makes it fail. Try again without that.
                Rails.logger.debug("### Retrying request without job-bookmarks parameter for user = #{u.name} - #{u.email}.")
                fetched_li_data = true
                request = connection.get_request("/v1/people/~:(id,first-name,last-name,maiden-name,email-address,location,industry,num-connections,num-connections-capped,summary,specialties,public-profile-url,last-modified-timestamp,associations,interests,publications,patents,languages,skills,certifications,educations,courses,volunteer,three-current-positions,three-past-positions,num-recommenders,recommendations-received,following,honors-awards)?format=json", service.token)
                info = JSON.parse(request.body)
                info["jobBookmarks"] = "ERROR FETCHING"
                if info["errorCode"] == 0
                  fetched_li_data = false
                  Rails.logger.error("### Error exporting LinkedIn data (without jobs-bookmarks) for user = #{u.name} - #{u.email}.  Details: #{info.inspect}")
                end
              end
            end

            if fetched_li_data
              Rails.logger.debug("### info = #{info.inspect}")
              result = LinkedinExport.where(:user_id => u.id)
              linkedin_data = nil
              if result.empty?
                linkedin_data = LinkedinExport.new()
                linkedin_data.user_id = u.id
              else
                linkedin_data = result.first
              end

              linkedin_data.linkedin_id = item["id"] = info["id"]
              linkedin_data.first_name = item["first-name"] = info["firstName"]
              linkedin_data.last_name = item["last-name"] = info["lastName"]
              linkedin_data.maiden_name = item["maiden-name"] = info["maidenName"]
              linkedin_data.email_address = item["email-address"] = info["emailAddress"]
              linkedin_data.location = item["location"] = info["location"]["name"] unless info["location"].nil?
              linkedin_data.industry = item["industry"] = info["industry"]
              linkedin_data.job_title = item["job-title"] = get_job_title(info["threeCurrentPositions"])
              linkedin_data.num_connections = item["num-connections"] = info["numConnections"]
              linkedin_data.num_connections_capped = item["num-connections-capped"] = info["numConnectionsCapped"]
              linkedin_data.summary = item["summary"] = info["summary"]
              linkedin_data.specialties = item["specialties"] = info["specialties"]
              linkedin_data.public_profile_url = item["public-profile-url"] = info["publicProfileUrl"]
              # TODO: the default timestamp format of the Time object is something like: 2016-07-12 14:26:15 +0000
              # which corresponds to 07/12/2016 2:26pm UTC
              # if we want to format the timestamp differently, use the strftime() method on the Time object
              linkedin_data.last_modified_timestamp = item["last-modified-timestamp"] = Time.at(info["lastModifiedTimestamp"].to_f / 1000)
              linkedin_data.associations = item["associations"] = info["associations"]
              linkedin_data.interests = item["interests"] = info["interests"]
              linkedin_data.publications = item["publications"] = info["publications"]
              linkedin_data.patents = item["patents"] = info["patents"]
              linkedin_data.languages = item["languages"] = info["languages"]
              linkedin_data.skills = item["skills"] = info["skills"]
              linkedin_data.certifications = item["certifications"] = info["certifications"]
              linkedin_data.educations = item["educations"] = info["educations"]
              linkedin_data.most_recent_school = item["most-recent-school"] = get_most_recent_school(info["educations"])
              linkedin_data.graduation_year = item["graduation-year"] = get_graduation_year(info["educations"])
              linkedin_data.major = item["major"] = get_major(info["educations"])
              linkedin_data.courses = item["courses"] = info["courses"]
              linkedin_data.volunteer = item["volunteer"] = info["volunteer"]
              linkedin_data.three_current_positions = item["three-current-positions"] = info["threeCurrentPositions"]
              linkedin_data.current_employer = item["current-employer"] = get_current_employer(info["threeCurrentPositions"])
              linkedin_data.three_past_positions = item["three-past-positions"] = info["threePastPositions"]
              linkedin_data.num_recommenders = item["num-recommenders"] = info["numRecommenders"]
              linkedin_data.recommendations_received = item["recommendations-received"] = info["recommendationsReceived"]
              linkedin_data.following = item["following"] = info["following"]
              linkedin_data.job_bookmarks = item["job-bookmarks"] = info["jobBookmarks"]
              linkedin_data.honors_awards = item["honors-awards"] = info["honorsAwards"]

              items.push(item)
              linkedin_data.save
            end
          else
            Rails.logger.debug("### LinkedIn service not registered for #{u.name}")
          end
        end
      end

      csv_result = CSV.generate do |csv|
        header = []
        header << "braven-id"
        header << "id"
        header << "first-name"
        header << "last-name"
        header << "maiden-name"
        header << "email-address"
        header << "location"
        header << "industry"
        header << "job-title"
        header << "num-connections"
        header << "num-connections-capped"
        header << "summary"
        header << "specialties"
        header << "public-profile-url"
        header << "last-modified-timestamp"
        header << "associations"
        header << "interests"
        header << "publications"
        header << "patents"
        header << "languages"
        header << "skills"
        header << "certifications"
        header << "educations"
        header << "most-recent-school"
        header << "graduation-year"
        header << "major"
        header << "courses"
        header << "volunteer"
        header << "three-current-positions"
        header << "current-employer"
        header << "three-past-positions"
        header << "num-recommenders"
        header << "recommendations-received"
        header << "following"
        header << "job-bookmarks"
        header << "honors-awards"
        csv << header
        items.each do |item|
          row = []
          row << item["braven-id"]
          row << item["id"]
          row << item["first-name"]
          row << item["last-name"]
          row << item["maiden-name"]
          row << item["email-address"]
          row << item["location"]
          row << item["industry"]
          row << item["job-title"]
          row << item["num-connections"]
          row << item["num-connections-capped"]
          row << item["summary"]
          row << item["specialties"]
          row << item["public-profile-url"]
          row << item["last-modified-timestamp"]
          row << item["associations"]
          row << item["interests"]
          row << item["publications"]
          row << item["patents"]
          row << item["languages"]
          row << item["skills"]
          row << item["certifications"]
          row << item["educations"]
          row << item["most-recent-school"]
          row << item["graduation-year"]
          row << item["major"]
          row << item["courses"]
          row << item["volunteer"]
          row << item["three-current-positions"]
          row << item["current-employer"]
          row << item["three-past-positions"]
          row << item["num-recommenders"]
          row << item["recommendations-received"]
          row << item["following"]
          row << item["job-bookmarks"]
          row << item["honors-awards"]
          csv << row
        end
      end
    end

    #def linked_in_export
      #respond_to do |format|
        #format.csv { render text: linked_in_export_guts }
      #end
    #end

    def get_job_title(threeCurrentPositionsNode)
      # Example of threeCurrentPositions:
      #   {
      #     "_total"=>1,
      #     "values"=>
      #     [
      #       {
      #         "company"=>{"id"=>3863006, "industry"=>"Higher Education", "name"=>"Braven", "size"=>"11-50", "type"=>"Non Profit"},
      #         "id"=>488965520,
      #         "isCurrent"=>true,
      #         "location"=>{"name"=>"New York City"},
      #         "startDate"=>{"month"=>12, "year"=>2013},
      #         "summary"=>"blah blah.",
      #         "title"=>"CTO"
      #       }
      #     ]
      #   }
      job_title = threeCurrentPositionsNode["values"].find {|job| job['isCurrent']==true}['title'] unless threeCurrentPositionsNode["_total"]==0
      return job_title
    end

    def get_current_employer(threeCurrentPositionsNode)
      # See get_job_title() for example of threeCurrentPositionsNode
      current_employer_node = threeCurrentPositionsNode["values"].find {|job| job['isCurrent']==true} unless threeCurrentPositionsNode["_total"]==0
      current_employer_company_node = current_employer_node["company"] unless current_employer_node.nil?
      current_employer = current_employer_company_node["name"] unless current_employer_company_node.nil?
      return current_employer
    end

    def get_most_recent_school(educationsNode)
      # Example of educationsNode: 
      # {
      #   "_total"=>2,
      #   "values"=>[
      #     {
      #       "degree"=>"Bachelors",
      #       "endDate"=>{"year"=>2006},
      #       "fieldOfStudy"=>"Computer Science and Mathematics",
      #       "grade"=>{},
      #       "id"=>11029769,
      #       "schoolName"=>"Boston University",
      #       "startDate"=>{"year"=>2004}
      #     },
      #     {
      #       "endDate"=>{"year"=>2004},
      #       "fieldOfStudy"=>"Computer Science and Mathematics",
      #       "grade"=>{},
      #       "id"=>13485812,
      #       "schoolName"=>"Rensselaer Polytechnic Institute",
      #       "startDate"=>{"year"=>2002}
      #     }
      #   ]
      # }
      # Assumes that LinkedIn returns them in reverse chronological order
      most_recent_school = educationsNode["values"][0]["schoolName"] unless educationsNode["_total"]==0
     return most_recent_school
    end

    def get_graduation_year(educationsNode)
      # See get_most_recent_school() for an example of the educationsNode
      graduation_year = educationsNode["values"][0]["endDate"] unless educationsNode["_total"]==0
      graduation_year = graduation_year["year"] unless graduation_year.nil?
      return graduation_year
    end

    def get_major(educationsNode)
      # See get_most_recent_school() for an example of the educationsNode
      major = educationsNode["values"][0]["fieldOfStudy"] unless educationsNode["_total"]==0
      return major
    end











  end
  # end


  def last_user_url
    @current_user.last_url = params[:last_url]
    @current_user.last_url_title = params[:last_url_title]
    @current_user.save

    # I also want to store the per-module, per-course
    # last item, so we can pick up where we left off on
    # the dynamic syllabus there too.
    url = URI.parse(params[:last_url])
    if url.query
      urlparams = CGI.parse(url.query)
      if urlparams.key?('module_item_id')
        mi = urlparams['module_item_id'].first
        tag = ContentTag.find(mi)
        context_module = tag.context_module

        p = UserModulePosition.where(
          :user_id => @current_user.id,
          :course_id => tag.context_id,
          :module_id => context_module.id
        )
        if p.empty?
          UserModulePosition.create(
            :user_id => @current_user.id,
            :course_id => tag.context_id,
            :module_id => context_module.id,
            :module_item_id => mi
          )
        else
          p = p.first
          p.module_item_id = mi
          p.save
        end
      end
    end


    render :nothing => true
  end

  def event_rsvps
    result = []
    CalendarEvent.find(params[:id]).get_gcal_rsvp_status.each do |attendee|
      obj = {}
      # Going to look up unconfirmed emails too because the imported emails might
      # not be formally confirmed in canvas while still being good for us (we confirmed
      # via the join server already)
      cc = CommunicationChannel.where(:path => attendee["email"], :path_type => 'email', :workflow_state => ['active', 'unconfirmed'])
      next if cc.empty?
      canvas_user = User.find(cc.first.user_id)
      obj['user_link'] = user_path(canvas_user)
      obj['user_name'] = canvas_user.name
      obj['user_status'] = attendee["responseStatus"]
      obj['user_status_text'] = case attendee["responseStatus"]
       when 'needsAction'
         'Not answered'
       else
         attendee["responseStatus"]
       end
      result << obj
    end

    render :json => result
  end

  def video_link
    obj = {}

    client = Google::APIClient.new(:application_name => 'Braven Canvas')

    file_store = Google::APIClient::FileStore.new(File.join(Rails.root, "config", "google_calendar_auth.json"))
    storage = Google::APIClient::Storage.new(file_store)
    client.authorization = storage.authorize
    calendar_api = client.discovered_api('calendar', 'v3')

    event = {
      'summary' => 'Canvas event',
      'start' => {
        'dateTime' => DateTime.now.iso8601,
        'timeZone' => 'America/Los_Angeles',
      },
      'end' => {
        'dateTime' => (DateTime.now + 1.hours).iso8601,
        'timeZone' => 'America/Los_Angeles',
      }
    }

    results = client.execute!(
      :api_method => calendar_api.events.insert,
      :parameters => {
        :calendarId => 'primary'},
      :body_object => event)

    event = results.data

    obj['link'] = event.hangout_link
    obj['gcal_id'] = event.id
    render :json => obj
  end

  # The official Canvas API doesn't offer user deletion but
  # we want it, so I'm implementing myself (based on the code
  # from the users_controller through the admin interface)
  def delete_user
    user = api_find(User, params[:id])
    if user.allows_user_to_remove_from_account?(@domain_root_account, @current_user)
      # this will not delete the record completely, but will mark it as deleted,
      # same as if you manually hit the button in the admin page.
      user.destroy
    end
    render :nothing => true
  end


  def dynamic_syllabus
    @course = Course.find(params[:course_id])

    @progressions = @current_user.context_module_progressions

    @editable = authorized_action(@course, @current_user, :update)
  end

  def dynamic_syllabus_edit
    @course = Course.find(params[:course_id])
    raise "Unauthorized" if !authorized_action(@course, @current_user, :update)
  end

  def save_dynamic_syllabus_edit
    @course = Course.find(params[:course_id])
    raise "Unauthorized" if !authorized_action(@course, @current_user, :update)

    @course.intro_title = params[:course_intro_title]
    @course.gradebook_text = params[:course_gradebook_text]
    @course.intro_text = params[:course_intro_text]
    @course.save

    params[:part_id].each_with_index do |part_id, idx|
      part = part_id == '' ? CoursePart.new : CoursePart.find(part_id.to_i)

      part.title = params[:part_title][idx]
      next if part.title == ''
      part.intro = params[:part_intro][idx]
      # The task box is removed for now, but I'm keeping the code
      # in case we want a custom section in it later.
      #part.task_box_title = params[:task_box_title][idx]
      #part.task_box_intro = params[:task_box_intro][idx]
      part.course_id = @course.id
      part.position = idx

      part.save
    end

    redirect_to "/courses/#{@course.id}/dynamic_syllabus/modules_edit"
  end

  def dynamic_syllabus_modules_edit
    @course = Course.find(params[:course_id])
    raise "Unauthorized" if !authorized_action(@course, @current_user, :update)

    @course_parts = CoursePart.where(:course_id => @course.id)
  end

  def save_dynamic_syllabus_modules_edit
    @course = Course.find(params[:course_id])
    raise "Unauthorized" if !authorized_action(@course, @current_user, :update)

    params[:module_id].each_with_index do |module_id, idx|
      mod = ContextModule.find(module_id)

      # Doing this instead of .save because running the callbacks
      # takes forever and we only ever touch these few auxiliary fields
      # here.
      mod.update_column(:intro_text, params[:intro_text][idx])
      mod.update_column(:image_url, params[:image_url][idx])
      mod.update_column(:part_id, (params[:part_id][idx] == '') ? nil : params[:part_id][idx])
    end

    redirect_to "/courses/#{@course.id}/dynamic_syllabus"
  end
end
