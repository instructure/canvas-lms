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
  # user_retained_data_batch is sensitive, but it can also be done via access_token
  before_filter :require_user, :except => [:magic_field_dump, :courses_for_email, :magic_fields_for_cohort, :course_cohort_information, :user_retained_data_batch, :prepare_qualtrics_links]
  skip_before_filter :verify_authenticity_token, :only => [:last_user_url, :set_user_retained_data, :delete_user, :user_retained_data_batch, :prepare_qualtrics_links]


  # used by the pdf annotator
  def submission_comment
    existing = SubmissionComment.where(
      :author_id => @current_user.id,
      :submission_id => params[:submission_id],
      :attached_to => params[:attachment_id],
      :x => params[:x],
      :y => params[:y]
    )
    comment = nil
    if existing.any?
      comment = existing.first
    else
      comment = SubmissionComment.new
      comment.author_id = @current_user.id
      comment.submission_id = params[:submission_id]
      comment.attached_to = params[:attachment_id]
      comment.x = params[:x]
      comment.y = params[:y]
    end

    if params[:comment].blank?
      comment.destroy
    else
      comment.comment = params[:comment]
      comment.save
    end

    render :json => comment.to_json
  end

  # I need to add the coordinates info to the comment model and use
  # that in here and a custom function to add it or something.
  def pdf_annotator
    attachment_id = params[:attachment_id]

    if Attachment.local_storage?
      data = File.read(Attachment.find(attachment_id).full_filename)
    else
      url = Attachment.find(attachment_id).download_url
      data = Net::HTTP.get(URI.parse(url))
    end

    submission = Submission.find(params[:submission_id])

    comments_html = ''
    count = 0
    submission.submission_comments.each do |comment|
      next if comment.x.nil?
      next if comment.comment.nil?
      next if comment.attached_to.to_s != attachment_id.to_s
      count += 1
      comments_html += '<div class="point '+(params[:highlight].to_s == comment.id.to_s ? 'highlighted' : '')+'" style="left: '+(comment.x).to_s+'px; top: '+(comment.y).to_s+'px;" title="'+CGI.escapeHTML(comment.comment)+'" data-x="'+comment.x.to_s+'" data-y="'+comment.y.to_s+'">'+count.to_s+'</div>'
    end

    image_data = nil

    IO::popen('convert -density 300 -scale x1200 -append - png:-', 'r+') do |io|
      io.write(data)
      io.close_write
      image_data = io.read
    end

    readonly = false
    if params[:readonly]
      readonly = true
    end

    render :text => '<!DOCTYPE html><html><head><link rel="stylesheet" href="/bz_annotator.css?v3" /></head><body><div id="resume"><img src="data:image/png;base64,' + Base64.encode64(image_data) + '" />'+comments_html+'<div id="commentary"><textarea></textarea><button class="save" type="button">Save</button><button class="cancel" type="button">Cancel</button><button class="delete">Delete</button></div></div><script>var submission_id='+submission.id.to_s+';var authtoken="'+form_authenticity_token+'"; var count='+count.to_s+'; var attachment_id='+attachment_id.to_s+'; var readonly='+readonly.to_s+';</script><script src="/bz_annotator.js?v3"></script></body></html>';
  end

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
      result["user_id"] = u.id
      u.enrollments.active.each do |e|
        result["course_ids"] << e.course_id
      end
    end

    render :json => result
  end

  # give it a set of course_id[]
  def course_cohort_information
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

    result = {}
    result["courses"] = []
    params[:course_ids].each do |course_id|
      course = Course.find(course_id)
      ci = {}
      ci["name"] = course.name
      ci["id"] = course.id
      ci["sections"] = []

      course.course_sections.each do |section|
        si = {}
        si["name"] = section.name
        si["id"] = section.id

        additional_info = CohortInfo.where(:course_id => course_id, :section_name => section.name).first
        if additional_info
          si["lc_name"] = additional_info.lc_name
          si["lc_email"] = additional_info.lc_email
          si["lc_phone"] = additional_info.lc_phone
          si["ta_name"] = additional_info.ta_name
          si["ta_email"] = additional_info.ta_email
          si["ta_phone"] = additional_info.ta_phone
          si["ta_office"] = additional_info.ta_office
          si["ll_times"] = additional_info.ll_times
          si["ll_location"] = additional_info.ll_location
        end

        si["enrollments"] = []
        section.enrollments.each do |enrollment|
          next if enrollment.user.nil?
          next if enrollment.user.pseudonym.nil?
          next if enrollment.user.name == "Test Student" # we dont need to filter this everywhere else!
          obj = {}
          obj["enrollment_id"] = enrollment.id
          obj["id"] = enrollment.user.id
          obj["name"] = enrollment.user.name
          obj["email"] = enrollment.user.pseudonym.unique_id
          obj["contact_email"] = enrollment.user.email
          obj["type"] = enrollment.type
          si["enrollments"] << obj
        end
        ci["sections"] << si
      end
      result["courses"] << ci
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
        user.ta_enrollments.active.each do |tae|
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
    # FIXME: add result["schema"] here with info about the requested fields.

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

      row = row.map{ |i|
        i.nil? ? "" : i.strip
      }

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

    if @is_staff
      @if_on_time_score = 0.0
      @response_object["audit_trace"].each do |at|
        #results << "#{at["points_given"]} #{at["points_amount"]} #{at["points_possible"]} via #{at["points_reason"]}"
        # if at["points_amount"] == at["points_amount_if_on_time"]
        if at["points_amount"] != 0
          @if_on_time_score += at["points_amount"]
        elsif at["points_reason"] == "past_due"
          @if_on_time_score += at["points_possible"] # allow for past due
        end
      end
    end


    cm = bzg.get_context_module(module_item_id)
    submission = bzg.get_participation_assignment(cm.course, cm).find_or_create_submission(user)
    @gradebook_grade = submission.nil? ? nil : submission.grade
  end

  def grades_download
    # view render
  end

  def do_grades_download
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
        time = 0
        time = result.first.updated_at.to_i unless result.empty?

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
        n['data-time-updated'] = time

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

    user = nil

    if params[:access_token]
      access_token = AccessToken.authenticate(params[:access_token])
      if access_token.nil?
        render :json => "Access denied, bad access token"
        return
      end

      if params[:user]
        if requesting_user.id != 1
          render :json => "Access denied, not admin"
          return
        end

        if params[:user].match(/[0-9]+/)
          user = User.find(params[:user])
        else
          user = Pseudonym.active.where(:unique_id => params[:user]).first
        end

        if user.nil?
          render :json => "Access denied, no such user"
          return
        end
      else
        user = access_token.user
      end
    else
      user = @current_user
    end

    if user.nil?
        render :json => "Access denied, not logged in"
        return
    end

    data = {}
    if params[:names]
      params[:names].each do |name|
        next if data[name]
        result = RetainedData.where(:user_id => user.id, :name => name)
        if params[:include_timings]
          obj = {}
          obj["value"] = result.empty? ? '' : result.first.value
          obj["timestamp"] = result.empty? ? 0 : result.first.updated_at.to_i
          data[name] = obj
        else
          data[name] = result.empty? ? '' : result.first.value
        end
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
    # like micrograding -- we only micro-grade (aka auto-grade) pages in modules, not assignments
    # assignment magic fields are just for persistant storage.
    is_wiki_page = request.referrer.match(/\/courses\/\d+\/pages\//)

    if is_wiki_page && was_new && !was_optional && (field_type != 'checkbox' || !answer.nil?) # Checkboxes are optional by nature unless there is an answer
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

  # This is not meant to be run in production! It's only for dev, test, and staging servers
  def reset_user_retained_data
    raise NotImplementedError.new "This method is not implemented for this configuration" unless BeyondZConfiguration.dev_tools_enabled
    raise ActionController::ParameterMissing.new "You must pass a user_id parameter to this method" unless params[:user_id]
    RetainedData.where(:user_id => params[:user_id]).destroy_all
    flash[:html_notice] = t("Magic field data deleted for user_id =  %{user_id}.", :user_id => params[:user_id])
    redirect_to settings_profile_path
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
      @user_id = user_id
      @params = params
    end
    
    def perform
      user = User.find(@user_id)
      csv = Export::GradeDownload.csv(user, @params)
      Mailer.bz_message(@params[:email], "Export Success: Course #{@params[:course_id]}", "Attached is your export data", "grades_download.csv" => csv).deliver
      
      csv
    end

    def on_permanent_failure(error)
      user = User.find(@user_id)
      er_id = Canvas::Errors.capture_exception("BzController::ExportGrades", error)[:error_report]
      # email us?
      Mailer.debug_message("Export FAIL", error.to_s).deliver
      Mailer.bz_message(user.email, "Export Failed :(", "Your grades download export didn't work. The tech team was also emailed to look into why.")
    end
  end
  
  class ExportWork # < Delayed::PerformableMethod
    def initialize(email)
      @email = email
    end

    def perform
      csv = linked_in_export_guts

      stringio = Zip::OutputStream.write_buffer(StringIO.new('')) do |zio|
        zio.put_next_entry("linkedin.csv")
        zio.write(csv)
        sleep 1 # wtf?
      end
      stringio.rewind

      Mailer.bz_message(@email, "Export Success", "Attached is your export data", "linkedin.zip" => stringio.sysread).deliver
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
            #request = connection.get_request("/v1/people/~:(id,first-name,last-name,maiden-name,email-address,location,industry,num-connections,num-connections-capped,summary,specialties,public-profile-url,last-modified-timestamp,associations,interests,publications,patents,languages,skills,certifications,educations,courses,volunteer,three-current-positions,three-past-positions,num-recommenders,recommendations-received,following,job-bookmarks,honors-awards)?format=json", service.token)
            request = connection.get_request("/v2/me", service.token)

            # NOTE: The 'suggestions' field was causing this error, so we're not fetching it:
            # {"errorCode"=>0, "message"=>"Internal API server error", "requestId"=>"Y4175L15PK", "status"=>500, "timestamp"=>1490298963387}
            # Also, I decided not to fetch picture-urls::(original)

            info = JSON.parse(request.body)

            if info["errorCode"] == 0
              fetched_li_data = false
              Rails.logger.error("### Error exporting LinkedIn data for user = #{u.name} - #{u.email}.  Details: #{info.inspect}")
              # TODO: if "message"=>"Unable to verify access token" we should unregister the user.  I reproduced this by registering a second
              # account with the same LinkedIn account.  It invalidated the first.

              # if info["message"] == "Internal API server error" # For certain LinkedIn accounts, requesting the job-bookmarks makes it fail. Try again without that.
                # Rails.logger.debug("### Retrying request without job-bookmarks parameter for user = #{u.name} - #{u.email}.")
                # fetched_li_data = true
                # request = connection.get_request("/v1/people/~:(id,first-name,last-name,maiden-name,email-address,location,industry,num-connections,num-connections-capped,summary,specialties,public-profile-url,last-modified-timestamp,associations,interests,publications,patents,languages,skills,certifications,educations,courses,volunteer,three-current-positions,three-past-positions,num-recommenders,recommendations-received,following,honors-awards)?format=json", service.token)
                # info = JSON.parse(request.body)
                # info["jobBookmarks"] = "ERROR FETCHING"
                # if info["errorCode"] == 0
                  # fetched_li_data = false
                  # Rails.logger.error("### Error exporting LinkedIn data (without jobs-bookmarks) for user = #{u.name} - #{u.email}.  Details: #{info.inspect}")
                # end
              # end
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
              linkedin_data.first_name = item["first-name"] = info["localizedFirstName"]
              linkedin_data.last_name = item["last-name"] = info["localizedLastName"]
              linkedin_data.maiden_name = item["maiden-name"] = info["localizedMaidenName"]
              # no longer available
              # linkedin_data.email_address = item["email-address"] = info["emailAddress"]
              linkedin_data.location = item["location"] = info["location"]["postalCode"] unless info["location"].nil?
              linkedin_data.industry = item["industry"] = info["industryName"]["localized"]["en_US"] unless info["industryName"].nil?

              linkedin_data.job_title = item["job-title"] = get_job_title(info["positions"])
              linkedin_data.num_connections = item["num-connections"] = nil # removed in V2
              linkedin_data.num_connections_capped = item["num-connections-capped"] = nil # removed in V2
              linkedin_data.summary = item["summary"] = info["headline"]["localized"]["en_US"] unless info["headline"].nil?
              linkedin_data.specialties = item["specialties"] = nil # removed in V2
              linkedin_data.public_profile_url = item["public-profile-url"] = "http://www.linkedin.com/in/#{info["vanityName"]}"
              # TODO: the default timestamp format of the Time object is something like: 2016-07-12 14:26:15 +0000
              # which corresponds to 07/12/2016 2:26pm UTC
              # if we want to format the timestamp differently, use the strftime() method on the Time object
              linkedin_data.last_modified_timestamp = item["last-modified-timestamp"] = Time.at(info["lastModified"].to_f / 1000)
              linkedin_data.associations = item["associations"] = nil # remove in V2

              linkedin_data.interests = item["interests"] = nil # removed in v2
              linkedin_data.publications = item["publications"] = info["publications"]
              linkedin_data.patents = item["patents"] = info["patents"]
              linkedin_data.languages = item["languages"] = info["languages"]
              linkedin_data.skills = item["skills"] = info["skills"]
              linkedin_data.certifications = item["certifications"] = info["certifications"]
              linkedin_data.educations = item["educations"] = info["educations"]
              linkedin_data.courses = item["courses"] = info["courses"]
              linkedin_data.volunteer = item["volunteer"] = info["volunteeringExperiences"]
              # note there is also volunteeringInterests which gives a list of causes we might find interesting

              linkedin_data.most_recent_school = item["most-recent-school"] = get_most_recent_school(info["educations"])
              linkedin_data.graduation_year = item["graduation-year"] = get_graduation_year(info["educations"])
              linkedin_data.major = item["major"] = get_major(info["educations"])

              linkedin_data.three_current_positions = item["three-current-positions"] = current_positions(info["positions"])
              linkedin_data.current_employer = item["current-employer"] = get_current_employer(info["positions"])
              linkedin_data.three_past_positions = item["three-past-positions"] = non_current_positions(info["positions"])

              linkedin_data.num_recommenders = item["num-recommenders"] = nil # removed in V2
              linkedin_data.recommendations_received = item["recommendations-received"] = nil # removed in V2
              linkedin_data.following = item["following"] = nil # removed in V2
              linkedin_data.job_bookmarks = item["job-bookmarks"] = nil # removed in V2

              linkedin_data.honors_awards = item["honors-awards"] = info["honors"]

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

    def get_job_title(positionsNode)
      return nil if positionsNode.nil?
      # positions is an object with items as properties, we need to find the one that does not have a endMonthYear as it its current
      positionsNode.each do |id, value|
        if value["endMonthYear"].nil?
          return value["title"]["localized"]["en_US"]
        end
      end
      return nil
    end

    def current_positions(positionsNode)
      remainder = []
      return remainder if positionsNode.nil?
      positionsNode.each do |k, v|
        if v["endMonthYear"].nil?
          remainder << v
        end
      end

      begin
        remainder.sort_by { |a| [a["startMonthYear"]["year"], a["startMonthYear"]["month"]] }
      rescue
        return []
      end
    end

    def non_current_positions(positionsNode)
      remainder = []
      return remainder if positionsNode.nil?
      positionsNode.each do |k, v|
        if !v["endMonthYear"].nil?
          remainder << v
        end
      end

      begin
        remainder.sort_by { |a| [a["startMonthYear"]["year"], a["startMonthYear"]["month"]] }
      rescue
        return []
      end
    end

    def get_current_employer(currentPositionsNode)
      cp = current_positions(currentPositionsNode)
      return nil if cp.length == 0
      current_employer_node = cp[-1]
      if current_employer_node
        return current_employer_node["companyName"]["localized"]["en_US"]
      else
        return nil
      end
    end

    def get_most_recent_school(educationsNode)
      most_recent = get_most_recent_school_node(educationsNode)
      begin
        return most_recent["schoolName"]["localized"]["en_US"]
      rescue
        return nil
      end
    end

    def get_most_recent_school_node(educationsNode)
      most_recent = nil
      return nil if educationsNode.nil?
      educationsNode.each do |k, v|
        next if v["startMonthYear"].nil?
        if most_recent.nil? || v["startMonthYear"]["year"] > most_recent["startMonthYear"]["year"] || (v["startMonthYear"]["year"] == most_recent["startMonthYear"]["year"] && v["startMonthYear"]["month"] && most_recent["startMonthYear"]["month"] && v["startMonthYear"]["month"] > most_recent["startMonthYear"]["month"])
          most_recent = v
        end
      end
      return most_recent
    end

    def get_graduation_year(educationsNode)
      return nil if educationsNode.nil?
      node = get_most_recent_school_node(educationsNode)
      if node.nil? || node["endMonthYear"].nil?
        return nil
      else
        return node["endMonthYear"]["year"]
      end
    end

    def get_major(educationsNode)
      return nil if educationsNode.nil?
      node = get_most_recent_school_node(educationsNode)
      if node.nil?
        return nil
      end

      begin
        return node["fieldsOfStudy"][0]["fieldOfStudyName"]["localized"]["en_US"]
      rescue
        return nil
      end
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
      if part.title == ''
        if part_id == ''
          next # skip since no need to create a new one if it is empty
        else
          part.destroy # but if it already exists, delete the existing one since this is an edit to remove it
          next
        end
      end
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


  # DOCUSIGN STUFF
  def docusign_authorize
    if @current_user.id != 1
      raise Exception.new "log in as the admin account to do this setup task"
    end

    url = "https://#{BeyondZConfiguration.docusign_host}/oauth/auth?" +
      "response_type=code&" +
      "scope=signature%20extended&" +
      "prompt=login&" + 
      "client_id=#{BeyondZConfiguration.docusign_api_key}&" +
      "redirect_uri=#{URI::encode(BeyondZConfiguration.docusign_return_url.sub('docusign_user_redirect', 'docusign_redirect'))}"

    redirect_to url
  end

  # this is where docusign redirects TO after an auth
  def docusign_redirect
    if @current_user.id != 1
      raise Exception.new "log in as the admin account to do this setup task"
    end

    code = params[:code]

    url = URI.parse("https://#{BeyondZConfiguration.docusign_host}/oauth/token")

    data = "grant_type=authorization_code&code=#{URI::encode(code)}"

    headers = {}
    headers["Content-Type"] = "application/x-www-form-urlencoded"
    headers["Authorization"] = "Basic #{Base64.strict_encode64("#{BeyondZConfiguration.docusign_api_key}" + ":" + "#{BeyondZConfiguration.docusign_api_secret}")}"

    account = Account.find(1)

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(url.request_uri, headers)
    request.body = data

    response = http.request(request)
    answer = JSON.parse(response.body)

    access_token = answer["access_token"]
    # and also time to get the user info and save that too

    url = URI.parse("https://#{BeyondZConfiguration.docusign_host}/oauth/userinfo")
    headers = {}
    headers["Authorization"] = "Bearer #{access_token}"
    request = Net::HTTP::Get.new(url.request_uri, headers)
    response = http.request(request)
    second_answer = JSON.parse(response.body)

    # You will need the account_id and the base_uri claims of the user that your application is acting on behalf on to make calls to the DocuSign API. 
    # it is under response.accounts[0]

    # access_token, token_type, refresh_token, expires_in
    # need to save that stuff for later

    account.docusign_access_token = answer["access_token"]
    account.docusign_refresh_token = answer["refresh_token"]
    account.docusign_account_id = second_answer["accounts"][0]["account_id"]
    account.docusign_base_uri = second_answer["accounts"][0]["base_uri"]
    account.docusign_token_expiration = DateTime.now + answer["expires_in"].to_i.seconds

    account.save

    render :text => "Docusign Account ready!"

  end

  def docusign_for_user
    doc = {}
    doc["emailSubject"] = "Please sign this for Braven"
    doc["compositeTemplates"] = [
      {
        "compositeTemplateId" => "1",
        "serverTemplates" => [
          {
            "sequence" => "1",
            "templateId" => @current_user.docusign_template_id

          }
        ],
        "inlineTemplates" => [
          {
            "sequence" => "1",
            "recipients" => {
              "signers" => [
                {
                  "email" => @current_user.email,
                  "name" => @current_user.name,
                  "recipientId" => "1",
                  "routingOrder" => "1",
                  "roleName" => "signer",
                  "clientUserId" => "portal_#{@current_user.id}"
                }
              ]
            }
          }
        ]
      }
    ]
    doc["status"] = "sent"

    account = Account.find(1)

    # The expiration returned seems to be 8 hours. That could change. Let's get a new access token using the
    # refresh token if we're 20 min away from expiration or it's already expired. Access tokens are good for 8 hours
    # but refresh tokens are good for 30 days. After 30 days of inactivity, we need to re-authorize.
    # See: https://developers.docusign.com/esign-rest-api/guides/authentication/oauth2-code-grant#using-refresh-tokens
    if account.docusign_token_expiration < (DateTime.now + 20.minutes)
      docusign_refresh_access_token_using_refresh_token
      account = Account.find(1)
    end

    url = URI.parse("#{account.docusign_base_uri}/restapi/v2/accounts/#{account.docusign_account_id}/envelopes")

    data = doc.to_json

    headers = {}
    headers["Content-Type"] = "application/json"
    headers["Authorization"] = "Bearer #{account.docusign_access_token}"

    account = Account.find(1)

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(url.request_uri, headers)
    request.body = data

    response = http.request(request)
    answer = JSON.parse(response.body)

    # now time to begin the signing process

    envelope_id = answer["envelopeId"]

    headers = {}
    headers["Content-Type"] = "application/json"
    headers["Authorization"] = "Bearer #{account.docusign_access_token}"

    doc = {
      "returnUrl" => "#{BeyondZConfiguration.docusign_return_url}",
      "authenticationMethod" => "none",
      "email" => @current_user.email,
      "userName" => @current_user.name,
      "clientUserId" => "portal_#{@current_user.id}"
    }

    url = URI.parse("#{account.docusign_base_uri}/restapi/v2/accounts/#{account.docusign_account_id}/envelopes/#{envelope_id}/views/recipient")

    request = Net::HTTP::Post.new(url.request_uri, headers)
    request.body = doc.to_json

    response = http.request(request)
    answer = JSON.parse(response.body)

    @link = answer["url"]

    # renders a view for the user
  end

  def docusign_user_redirect
    event = params[:event]

    if event == 'signing_complete'
      @current_user.accept_terms
      @current_user.save
      redirect_to(post_terms_accept_url)
    else
      render :text => "Sorry, but to access this system, you must sign the documentation. If you have concerns about it or believe you are seeing this message in error, please contact Braven."
    end
  end

  def docusign_refresh_access_token_using_refresh_token
    account = Account.find(1)

    url = URI.parse("https://#{BeyondZConfiguration.docusign_host}/oauth/token")

    # This can happen if we never authorize DocuSign in the first place.
    Rails.logger.error "The DocuSign refresh_token isn't set. Go here to refresh it: #{HostUrl.default_host}/bz/docusign_authorize" if account.docusign_refresh_token.nil?

    data = "grant_type=refresh_token&refresh_token=#{URI::encode(account.docusign_refresh_token)}"

    headers = {}
    headers["Content-Type"] = "application/x-www-form-urlencoded"
    headers["Authorization"] = "Basic #{Base64.strict_encode64("#{BeyondZConfiguration.docusign_api_key}" + ":" + "#{BeyondZConfiguration.docusign_api_secret}")}"

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(url.request_uri, headers)
    request.body = data

    response = http.request(request)
    answer = JSON.parse(response.body)

    if answer["access_token"].blank? || answer["refresh_token"].blank? || answer["expires_in"].blank?
      raise Exception.new "ERROR refreshing access token using refresh token. Go to #{HostUrl.default_host}/bz/docusign_authorize to fix it -- \n #{response.body}"
    end

    account.docusign_access_token = answer["access_token"] # This lasts for about 8 hours
    account.docusign_refresh_token = answer["refresh_token"] # This lasts for about 30 days
    account.docusign_token_expiration = DateTime.now + answer["expires_in"].to_i.seconds

    account.save
  end
  # end docusign

  # qualtrics
  def prepare_qualtrics_links
    # this is meant to be called from the join server's sync to lms, so it does the
    # access token for permission check

    access_token = AccessToken.authenticate(params[:access_token])
    if access_token.nil?
      render :json => "Access denied"
      return
    end

    requesting_user = access_token.user
    if requesting_user.id != 1
      render :json => "Not admin"
      return
    end

    course_id = params[:course_id]

    if course_id.blank?
      render :json => "no course id"
      return
    end

    course = Course.find(course_id)

    # I need to go through all the students in the course and if they don't already have
    # a qualtrics link, go ahead and make one for them via a qualtrics mailing list.

    # the survey ids...
    preaccel_id = params[:preaccel_id]
    postaccel_id = params[:postaccel_id]

    if preaccel_id.blank? && postaccel_id.blank?
      render :json => "no survey id"
      return
    end

    preaccel_students = []
    postaccel_students = []

    # TODO: need to update this logic where it will re-set up the qualtrics link if the survey ID has changed in the SF template.
    # Right now, it only happens the first time they are synced.
    course.students.active.each do |student|
      unless preaccel_id.blank?
        r = RetainedData.get_for_course(course_id, student.id, "qualtrics_link_preaccelerator_survey")
        if r.nil?
          preaccel_students << student
        end
      end

      unless postaccel_id.blank?
        r = RetainedData.get_for_course(course_id, student.id, "qualtrics_link_postaccelerator_survey")
        if r.nil?
          postaccel_students << student
        end
      end
    end

    all_new_students = preaccel_students | postaccel_students

    if all_new_students.empty?
      render :json => "no new students"
      return
    end

    # create the mailing list for this sync
    # see: https://api.qualtrics.com/reference#create-mailing-lists
    #
    # Note that we create a new mailing list for each sync when ideally we would
    # have a single mailing list per course. We do this b/c the mailing list is what we
    # use to create the Distribution List (which creates the survey links tied to each person)
    # and if we use a single mailing list and update it on subsequent sync, it *could* invalidate
    # the existing survey links for people synced before. Also, it was just a huge pain in the neck
    # trying to update a single mailing list on subsequent syncs b/c the API would return OK before the people
    # where actually in the list and then when we tried to create the distribution list immediatly after,
    # they would be missing. The logic to keep polling the list until they are actually in there is
    # harder than simply waiting for the newly created list to be populated.
    mailing_list_name = "#{course.course_code} via sync #{DateTime.now}"
    mailing_list_id = nil

    url = URI.parse("https://#{BeyondZConfiguration.qualtrics_host}/API/v3/mailinglists")
    headers = {}
    headers["Content-Type"] = "application/json"
    headers["X-API-TOKEN"] = BeyondZConfiguration.qualtrics_api_token
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    Rails.logger.info "### Creating new Qualtrics mailing list called '#{mailing_list_name}'"
    data = {}
    data["libraryId"] = BeyondZConfiguration.qualtrics_library_id
    data["name"] = mailing_list_name
    request = Net::HTTP::Post.new(url.request_uri, headers)
    request.body = data.to_json

    response = http.request(request)
    obj = JSON.parse(response.body)

    if obj["meta"]["httpStatus"] != '200 - OK'
      raise Exception.new response.body
    end
    Rails.logger.info "### Qualtrics API call response for creating new mailing list: #{response.inspect} - #{response.body}"

    mailing_list_id = obj["result"]["id"]

    # add the necessary students to this list
    # see: https://api.qualtrics.com/reference#create-contacts-import

    additional_data_from_join_server = JSON.parse(params[:additional_data])
    Rails.logger.debug "### Qualtrics additional_data_from_join_server = #{additional_data_from_join_server.to_json}"

    sync = {}
    sync["contacts"] = []
    all_new_students.each do |student|
      s = {}
      s["unsubscribed"] = 0
      s["firstName"] = student.first_name
      s["lastName"] = student.last_name
      s["email"] = student.email
      s["language"] = "EN"

      ed = {}
      if additional_data_from_join_server[student.id.to_s]
        ed["Site"] = additional_data_from_join_server[student.id.to_s]["site"]
        ed["Student ID"] = additional_data_from_join_server[student.id.to_s]["student_id"]
        ed["Salesforce ID"] = additional_data_from_join_server[student.id.to_s]["salesforce_id"]
      else
        Rails.logger.info "### No Qualtrics additional_data_from_join_server for student.id = #{student.id} was found. Didn't set embeddedData"
      end

      s["embeddedData"] = ed

      sync["contacts"] << s
    end

 
    url = URI.parse("https://#{BeyondZConfiguration.qualtrics_host}/API/v3/mailinglists/#{mailing_list_id}/contactimports")

    headers = {}
    headers["Content-Type"] = "application/json"
    headers["X-API-TOKEN"] = BeyondZConfiguration.qualtrics_api_token

    request = Net::HTTP::Post.new(url.request_uri, headers)
    request.body = sync.to_json
    Rails.logger.debug "### Sending contact to qualtrics with embedded data: #{request.inspect} - #{request.body}"

    response = http.request(request)
    obj = JSON.parse(response.body)
    if obj["meta"]["httpStatus"] != '200 - OK'
      raise Exception.new response.body
    end

      Rails.logger.info "###: Received response from qualtrics API for sending contact information: #{response.body}"

    # now create the links for the people...
    # see https://api.qualtrics.com/reference#distribution-create-1
    # (if it doesn't jump, go to "Generate Distribution Links" header)

    do_qualtrics_list(course_id, http, mailing_list_id, preaccel_students, preaccel_id, "qualtrics_link_preaccelerator_survey", "Pre-accelerator")
    do_qualtrics_list(course_id, http, mailing_list_id, postaccel_students, postaccel_id, "qualtrics_link_postaccelerator_survey", "Post-accelerator")

    render :json => "success"
  end

  def fetch_qualtrics_links(http, create_id, survey_id) 
    url = URI.parse("https://#{BeyondZConfiguration.qualtrics_host}/API/v3/distributions/#{create_id}/links?surveyId=" + survey_id)

    headers = {}
    headers["X-API-TOKEN"] = BeyondZConfiguration.qualtrics_api_token
    request = Net::HTTP::Get.new(url.request_uri, headers)

    response = http.request(request)
    obj = JSON.parse(response.body)

    if obj["meta"]["httpStatus"] != '200 - OK'
      raise Exception.new response.body
    end

    Rails.logger.info "### Fetched Qualtrics links for survey_id = #{survey_id}: #{response.body}"

    obj
  end

  def do_qualtrics_list(course_id, http, mailing_list_id, students_list, survey_id, magic_field_name, distrib_name)
    if students_list.any?
      create_command = {}
      create_command["surveyId"] = survey_id
      create_command["description"] = "#{distrib_name} distribution from sync #{DateTime.now}"
      create_command["action"] = "CreateDistribution"
      create_command["mailingListId"] = mailing_list_id

   
      url = URI.parse("https://#{BeyondZConfiguration.qualtrics_host}/API/v3/distributions")

      headers = {}
      headers["Content-Type"] = "application/json"
      headers["X-API-TOKEN"] = BeyondZConfiguration.qualtrics_api_token

      request = Net::HTTP::Post.new(url.request_uri, headers)
      request.body = create_command.to_json

      response = http.request(request)
      obj = JSON.parse(response.body)

      if obj["meta"]["httpStatus"] != '200 - OK'
        raise Exception.new response.body
      end

      Rails.logger.info "### Created Qualtrics Distribution list for survey_id = #{survey_id}, mailing_list_id = #{mailing_list_id}: #{response.body}"

      create_id = obj["result"]["id"]

      obj = fetch_qualtrics_links(http, create_id, survey_id)

      # The mailing list takes a little bit to actually be populated so we can create the distribution list off of it
      # but the API just returns OK so we have to poll the result here until it actually returns content.
      tries = 0
      while tries < 10 && obj["result"]["elements"].empty?
        tries += 1
        sleep(tries * 2) # sleep longer and longer so we don't over-poll
        obj = fetch_qualtrics_links(http, create_id, survey_id)
      end

      handle_qualtrics_page(obj, students_list, course_id, magic_field_name)

      while !obj["result"]["nextPage"].blank?
        Rails.logger.info "next page " + obj["result"]["nextPage"]
        url = URI.parse(obj["result"]["nextPage"])

        headers = {}
        headers["X-API-TOKEN"] = BeyondZConfiguration.qualtrics_api_token
        request = Net::HTTP::Get.new(url.request_uri, headers)

        response = http.request(request)
        obj = JSON.parse(response.body)

        if obj["meta"]["httpStatus"] != '200 - OK'
          raise Exception.new response.body
        end

        Rails.logger.info "### Handling new Qualtrics page for the above Distribution list: #{response.body}"

        handle_qualtrics_page(obj, students_list, course_id, magic_field_name)
      end
    end
  end

  def handle_qualtrics_page(obj, students_list, course_id, magic_field_name)
    obj["result"]["elements"].each do |contact|
      students_list.each do |student|
        if student.email == contact["email"]
          r = RetainedData.get_for_course(course_id, student.id, magic_field_name)
          if r.nil?
            r = RetainedData.new
            r.user_id = student.id
            r.name = magic_field_name
          end
          r.value = contact["link"]
          r.save
        end
      end
    end
  end

  # end qualtrics
end
