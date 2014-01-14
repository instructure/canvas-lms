module Wiziq

  class WiziqClassHelper
    attr_reader :wiziq_conference

    def initialize(wiziq_conference)
      @wiziq_conference = wiziq_conference
    end

    @@attributes ||= []
    consts =  ApiConstants::ParamsSchedule.constants
    consts.each do |attr|
      @@attributes << ApiConstants::ParamsSchedule.const_get(attr)
      attr_accessor ApiConstants::ParamsSchedule.const_get(attr)
    end

    def get_values_hash
      raise "Wiziq_conference attribute is not set." if @wiziq_conference.nil?
      hash = Hash.new
      time_now = @wiziq_conference.time_zone.now
      duration = @wiziq_conference.duration.to_i
      duration = 300 if duration < 1 || duration > 300
      hash.store ApiConstants::ParamsSchedule::TITLE, @wiziq_conference.title
      hash.store ApiConstants::ParamsSchedule::DURATION , duration
      hash.store ApiConstants::ParamsSchedule::START_DATETIME,  time_now.strftime("%m/%d/%Y %H:%M:%S %p")
      hash.store ApiConstants::ParamsSchedule::TIMEZONE, @wiziq_conference.time_zone.tzinfo.name
      hash.store ApiConstants::ParamsSchedule::COURSE_ID, @wiziq_conference.context_id
      hash.store ApiConstants::ParamsSchedule::PRESENTER_ID , @wiziq_conference.user.id
      hash.store ApiConstants::ParamsSchedule::PRESENTER_NAME, @wiziq_conference.user.name
      hash
    end
  end

end
