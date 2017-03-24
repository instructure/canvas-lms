# This holds BZ custom endpoints for updating our
# custom data.

require 'google/api_client'
require 'google/api_client/auth/storage'
require 'google/api_client/auth/storages/file_store'

require 'csv'

class BzController < ApplicationController

  before_filter :require_user
  skip_before_filter :verify_authenticity_token, :only => [:last_user_url, :set_user_retained_data, :delete_user]

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
    items = nil
    if module_sequence.nil?
      # view the entire course
      items = []
      Course.find(@course_id.to_i).context_modules.not_deleted.each do |ms|
        items += ms.content_tags_visible_to(@current_user)
      end
    else
      # view just one module inside a course
      items = Course.find(@course_id.to_i).context_modules.not_deleted[module_sequence.to_i].content_tags_visible_to(@current_user)
    end
    @pages = []
    items.each do |item|
      if item.content_type == "WikiPage"
        wp = WikiPage.find(item.content_id)
        @pages << wp
      end
    end
  end

  def user_retained_data
    result = RetainedData.where(:user_id => @current_user.id, :name => params[:name])
    data = ''
    unless result.empty?
      data = result.first.value
    end
    render :json => data
  end

  def set_user_retained_data
    result = RetainedData.where(:user_id => @current_user.id, :name => params[:name])
    data = nil
    if result.empty?
      data = RetainedData.new()
      data.user_id = @current_user.id
      data.path = request.referrer
      data.name = params[:name]
    else
      data = result.first
    end

    data.value = params[:value]
    data.save
    render :nothing => true
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

  def linked_in_export
    Rails.logger.debug("### linkedin_data_export - begin")

    connection = LinkedIn::Connection.new

    course = Course.find(params[:course])
    all_fields = {}
    items = []
    course.enrollments.each do |enrollment|
      u = User.find(enrollment.user_id)
      item = {}
      item["braven-id"] = u.id

      u.user_services.select{|s| !UserService.configured_service?(s.service) || feature_and_service_enabled?(s.service) }.each do |service|
        if service.service == "linked_in"
          Rails.logger.debug("### Found registered LinkedIn service for #{u.name}: #{service.service_user_link}")

          # See: https://developer.linkedin.com/docs/fields/full-profile
          request = connection.get_request("/v1/people/~:(id,first-name,last-name,maiden-name,email-address,location,industry,num-connections,num-connections-capped,summary,specialties,public-profile-url,last-modified-timestamp,associations,interests,publications,patents,languages,skills,certifications,educations,courses,volunteer,three-current-positions,three-past-positions,num-recommenders,recommendations-received,following,job-bookmarks,honors-awards)?format=json", service.token)

          # TODO: The 'suggestions' field was causing this error, so we're not fetching it:
          # {"errorCode"=>0, "message"=>"Internal API server error", "requestId"=>"Y4175L15PK", "status"=>500, "timestamp"=>1490298963387}
          # Also, I decided not to fetch picture-urls::(original)

          info = JSON.parse(request.body)

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
          linkedin_data.location = item["location"] = info["location"]
          linkedin_data.industry = item["industry"] = info["industry"]
          linkedin_data.num_connections = item["num-connections"] = info["numConnections"]
          linkedin_data.num_connections_capped = item["num-connections-capped"] = info["numConnectionsCapped"]
          linkedin_data.summary = item["summary"] = info["summary"]
          linkedin_data.specialties = item["specialties"] = info["specialties"]
          linkedin_data.public_profile_url = item["public-profile-url"] = info["publicProfileUrl"]
          linkedin_data.last_modified_timestamp = item["last-modified-timestamp"] = Time.strptime(info["lastModifiedTimestamp"].to_s, '%Q')
          linkedin_data.associations = item["associations"] = info["associations"]
          linkedin_data.interests = item["interests"] = info["interests"]
          linkedin_data.publications = item["publications"] = info["publications"]
          linkedin_data.patents = item["patents"] = info["patents"]
          linkedin_data.languages = item["languages"] = info["languages"]
          linkedin_data.skills = item["skills"] = info["skills"]
          linkedin_data.certifications = item["certifications"] = info["certifications"]
          linkedin_data.educations = item["educations"] = info["educations"]
          linkedin_data.courses = item["courses"] = info["courses"]
          linkedin_data.volunteer = item["volunteer"] = info["volunteer"]
          linkedin_data.three_current_positions = item["three-current-positions"] = info["threeCurrentPositions"]
          linkedin_data.three_past_positions = item["three-past-positions"] = info["threePastPositions"]
          linkedin_data.num_recommenders = item["num-recommenders"] = info["numRecommenders"]
          linkedin_data.recommendations_received = item["recommendations-received"] = info["recommendationsReceived"]
          linkedin_data.following = item["following"] = info["following"]
          linkedin_data.job_bookmarks = item["job-bookmarks"] = info["jobBookmarks"]
          linkedin_data.honors_awards = item["honors-awards"] = info["honorsAwards"]

          items.push(item)
          linkedin_data.save

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
      header << "courses"
      header << "volunteer"
      header << "three-current-positions"
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
        row << item["courses"]
        row << item["volunteer"]
        row << item["three-current-positions"]
        row << item["three-past-positions"]
        row << item["num-recommenders"]
        row << item["recommendations-received"]
        row << item["following"]
        row << item["job-bookmarks"]
        row << item["honors-awards"]
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
      if urlparams['module_item_id']
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
