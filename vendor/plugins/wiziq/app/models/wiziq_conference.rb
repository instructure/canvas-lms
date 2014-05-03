class WiziqConference < WebConference

  include Wiziq::ApiConstants

  attr_reader :time_zone, :attendee_url, :presenter_url

  def admin_join_url(user, return_to="http://www.instructure.com")
    join_wiziq_conference
    @presenter_url
  end

  def participant_join_url(user, return_to="http://www.instructure.com")
    join_wiziq_conference_as_attendee(user)
  end

  def conference_status
    aglive_com = Wiziq::AgliveComUtil.new(ApiMethods::LIST)
    begin
      class_status = aglive_com.get_wiziq_class_status(self.conference_key)
      return :active if class_status["time_to_start"] == "-1" and class_status["status"] == 'upcoming'
      return :closed
    rescue
      :closed
    end
  end

  def get_class_presenter_info
    return if !@presenter_url.blank?
    aglive_com = Wiziq::AgliveComUtil.new(ApiMethods::LIST)
    class_presenter_info = aglive_com.get_class_presenter_info(self.conference_key)
    @presenter_url = class_presenter_info["presenter_url"]
  end

  def schedule_wiziq_class
    @time_zone = user.time_zone || context.root_account.default_time_zone || Time.zone
    aglive_com = Wiziq::AgliveComUtil.new(ApiMethods::SCHEDULE)
    self.duration = 300 if self.long_running?
    wiziq_class = Wiziq::WiziqClassHelper.new(self)
    schedule_response_hash = aglive_com.schedule_class(wiziq_class.get_values_hash)
    return false if schedule_response_hash["code"] > 0
    @presenter_url  = schedule_response_hash["presenters"][0]["presenter_url"]
    self.conference_key = schedule_response_hash["class_id"]
    save
    true
  end

  private

  def join_wiziq_conference
    get_class_presenter_info if !self.conference_key.blank? or schedule_wiziq_class
  end

  def join_wiziq_conference_as_attendee(user)
    # we always add the attendee, even if they've already been added, as that
    # appears to be the only way to get the correct launch url back
    add_attendee_to_wiziq_session(user)
  end

  def add_attendee_to_wiziq_session(user)
    aglive_com = Wiziq::AgliveComUtil.new(ApiMethods::ADDATTENDEE)
    add_attendee_hash = aglive_com.add_attendee_to_session(self.conference_key, user.id, user.name)
    add_attendee_hash["attendee_url"]
  end

end
