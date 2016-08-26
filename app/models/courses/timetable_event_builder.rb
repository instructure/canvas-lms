module Courses
  class TimetableEventBuilder
    # builds calendar events for a course (or course sections) according to a timetable

    attr_reader :course, :course_section, :event_context, :errors
    def initialize(course: nil, course_section: nil)
      raise "require course" unless course
      @course = course
      @course_section = course_section
      @event_context = course_section ? course_section : course
    end

    # generates individual events from a simplified "timetable" between the course/section start and end dates
    # :weekdays - days of week (0-Sunday, 1-Monday, 2-Tuesday, 3-Wednesday, 4-Thursday, 5-Friday, 6-Saturday)
    # :start_time - basically any time that can be parsed by the magic (e.g. "11:30 am")
    # :end_time - ditto
    # :location_name (optional)
    def generate_event_hashes(timetable_hashes)
      time_zone = course.time_zone
      event_hashes = []
      timetable_hashes.each do |timetable_hash|
        course_start_at = timetable_hash[:course_start_at]
        course_end_at = timetable_hash[:course_end_at]

        parse_weekdays_string(timetable_hash[:weekdays]).each do |wday|
          location_name = timetable_hash[:location_name]

          current_date = course_start_at.to_date
          if current_date.wday != wday
            offset = wday - current_date.wday
            offset += 7 if offset < 0
            current_date += offset # should be on the right day now
          end

          while current_date < course_end_at
            event_start_at = time_zone.parse("#{current_date} #{timetable_hash[:start_time]}")
            event_end_at = time_zone.parse("#{current_date} #{timetable_hash[:end_time]}")

            if event_start_at > course_start_at && event_end_at < course_end_at
              event_hash = {:start_at => event_start_at, :end_at => event_end_at}
              event_hash[:location_name] = location_name if location_name
              event_hashes << event_hash
            end
            current_date += 7 # move to next week
          end
        end
      end
      event_hashes
    end

    # expects an array of hashes
    # with :start_at, :end_at required
    # and optionally :location_name (other attributes could be added here if so desired)
    # :code can be used to give it a unique identifier for syncing (otherwise will be generated based on the times)
    def create_or_update_events(event_hashes)
      timetable_codes = event_hashes.map{|h| h[:code]}
      raise "timetable codes can't be blank" if timetable_codes.any?(&:blank?)

      # destroy unused events
      event_context.calendar_events.active.for_timetable.where.not(:timetable_code => timetable_codes).
        update_all(:workflow_state => 'deleted', :deleted_at => Time.now.utc)

      existing_events = event_context.calendar_events.where(:timetable_code => timetable_codes).to_a.index_by(&:timetable_code)
      event_hashes.each do |event_hash|
        CalendarEvent.unique_constraint_retry do |retry_count|
          code = event_hash[:code]
          event = event_context.calendar_events.where(:timetable_code => code).first if retry_count > 0
          event ||= existing_events[code] || create_new_event(event_hash)
          sync_event(event, event_hash)
        end
      end
    end

    ALLOWED_TIMETABLE_KEYS = [:weekdays, :course_start_at, :course_end_at, :start_time, :end_time, :location_name]
    def process_and_validate_timetables(timetable_hashes)
      timetable_hashes.each do |hash|
        hash.slice!(*ALLOWED_TIMETABLE_KEYS)
      end
      unless timetable_hashes.all?{|hash|  Time.parse(hash[:start_time]) rescue nil}
        add_error("invalid start time(s)") # i'm too lazy to be more specific
      end
      unless timetable_hashes.all?{|hash| Time.parse(hash[:end_time]) rescue nil}
        add_error("invalid end time(s)")
      end

      default_start_at = (course_section && course_section.start_at) || course.start_at || course.enrollment_term.start_at
      default_end_at = (course_section && course_section.end_at) || course.conclude_at || course.enrollment_term.end_at

      timetable_hashes.each do |hash|
        hash[:course_start_at] ||= default_start_at
        hash[:course_end_at] ||= default_end_at
        hash[:weekdays] = standardize_weekdays_string(hash[:weekdays])
      end
      add_error("no start date found") unless timetable_hashes.all?{|hash| hash[:course_start_at]}
      add_error("no end date found") unless timetable_hashes.all?{|hash| hash[:course_end_at]}
    end

    def process_and_validate_event_hashes(event_hashes)
      add_error("start_at and end_at are required") unless event_hashes.all?{|h| h[:start_at] && h[:end_at]}

      event_hashes.each do |event_hash|
        event_hash[:code] ||= generate_timetable_code_for(event_hash) # ensure timetable codes
      end
      timetable_codes = event_hashes.map{|h| h[:code]}
      add_error("events (or codes) are not unique") unless timetable_codes.uniq.count == timetable_codes.count # too lazy to be specific here too
    end

    protected

    WEEKDAY_STR_MAP = {
      'sunday' => 'Sun', 'monday' => 'Mon', 'tuesday' => 'Tue', 'wednesday' => 'Wed', 'thursday' => 'Thu', 'friday' => 'Fri', 'saturday' => 'Sat',
      'su' => 'Sun', 'm' => 'Mon', 't' => 'Tue', 'w' => 'Wed', 'th' => 'Thu', 'f' => 'Fri', 's' => 'Sat'
    }.freeze
    def standardize_weekdays_string(weekdays_string)
      # turn strings like "M,W" into a standard string "Mon,Wed" (for sending back to the client)
      weekday_strs = weekdays_string.split(",").map do |str|
        str = str.strip.downcase
        WEEKDAY_STR_MAP[str] || str.capitalize
      end
      if weekday_strs.any?{|s| !WEEKDAY_TO_INT_MAP[s]}
        add_error("weekdays are not valid")
        nil
      else
        weekday_strs.join(",")
      end
    end

    WEEKDAY_TO_INT_MAP = {
      'Sun' => 0, 'Mon' => 1, 'Tue' => 2, 'Wed' => 3, 'Thu' => 4, 'Fri' => 5, 'Sat' => 6
    }.freeze
    def parse_weekdays_string(weekdays_string)
      # turn our standard string (e.g. "Tue,Thu") into an array of our special numbers
      weekdays_string.split(",").map{|s| WEEKDAY_TO_INT_MAP[s]}
    end

    def create_new_event(event_hash)
      event = event_context.calendar_events.new
      event.timetable_code = event_hash[:code]
      if course_section
        event.effective_context_code = course.asset_string
      end
      event
    end

    def sync_event(event, event_hash)
      event.workflow_state = 'active'
      event.title = event_hash[:title] || course.name
      event.start_at = event_hash[:start_at]
      event.end_at = event_hash[:end_at]
      event.location_name = event_hash[:location_name] if event_hash[:location_name]
      event.save! if event.changed?
    end

    def generate_timetable_code_for(event_hash)
      "#{event_context.asset_string}_#{event_hash[:start_at].to_i}-#{event_hash[:end_at].to_i}"
    end

    def add_error(error)
      @errors ||= []
      @errors << error
    end
  end
end