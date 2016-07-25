require_relative('../../spec_helper')

describe Courses::TimetableEventBuilder do
  describe "#process_and_validate_timetables" do
    let(:builder) { described_class.new(course: course) }

    it "should require valid start and end times" do
      tt_hash = {:weekdays => 'monday', :start_time => "hoopyfrood", :end_time => "42 oclock",
        :course_start_at => 1.day.from_now, :course_end_at => 1.week.from_now}
      builder.process_and_validate_timetables([tt_hash])
      expect(builder.errors).to match_array(["invalid start time(s)", "invalid end time(s)"])
    end

    it "should require a start and end date" do
      tt_hash = {:weekdays => 'tuesday', :start_time => "11:30 am", :end_time => "12:30 pm"}
      builder.process_and_validate_timetables([tt_hash])
      expect(builder.errors).to match_array(["no start date found", "no end date found"])
    end

    it "should require valid weekdays" do
      builder.course.enrollment_term.tap do |term|
        term.start_at = DateTime.parse("2016-05-06 1:00pm -0600")
        term.end_at = DateTime.parse("2016-05-19 9:00am -0600")
      end

      tt_hash = {:weekdays => 'wednesday,humpday', :start_time => "11:30 am", :end_time => "12:30 pm"}
      builder.process_and_validate_timetables([tt_hash])
      expect(builder.errors).to match_array(["weekdays are not valid"])
    end
  end

  describe "#generate_event_hashes" do
    let(:builder) { described_class.new(course: course) }

    it "should generate a bunch of event hashes" do
      builder.course.tap do |c|
        c.start_at = DateTime.parse("2016-05-06 1:00pm -0600") # on a friday - should offset to thursday
        c.conclude_at = DateTime.parse("2016-05-19 9:00am -0600") # on a thursday, but before the course time - shouldn't create an event that day
        c.time_zone = 'America/Denver'
      end

      tt_hash = {:weekdays => "T,Th", :start_time => "3 pm", :end_time => "4:30 pm"} # tuesdays and thursdays from 3:00-4:30pm
      builder.process_and_validate_timetables([tt_hash])
      expect(builder.errors).to be_blank

      expected_events = [
        { :start_at => DateTime.parse("2016-05-10 3:00 pm -0600"), :end_at => DateTime.parse("2016-05-10 4:30 pm -0600")},
        { :start_at => DateTime.parse("2016-05-12 3:00 pm -0600"), :end_at => DateTime.parse("2016-05-12 4:30 pm -0600")},
        { :start_at => DateTime.parse("2016-05-17 3:00 pm -0600"), :end_at => DateTime.parse("2016-05-17 4:30 pm -0600")}
      ]
      expect(builder.generate_event_hashes([tt_hash])).to match_array(expected_events)
    end

    it "should work across daylight savings time changes (sigh)" do
      builder.course.tap do |c|
        c.start_at = DateTime.parse("2016-03-09 1:00pm -0600") # on a wednesday
        # DST transition happened across March 13, 2016
        c.conclude_at = DateTime.parse("2016-03-18 8:00pm -0600") # on a friday, but after the course time - should create an event that day
        c.time_zone = 'America/Denver'
      end

      tt_hash = {:weekdays => "Monday,Friday", :start_time => "11:30", :end_time => "13:00"} # mondays and fridays from 11:30-1:00
      builder.process_and_validate_timetables([tt_hash])
      expect(builder.errors).to be_blank
      # should convert :weekdays to a standard format
      expect(tt_hash[:weekdays]).to eq "Mon,Fri"

      expected_events = [
        { :start_at => DateTime.parse("2016-03-11 11:30 am -0700"), :end_at => DateTime.parse("2016-03-11 1:00 pm -0700")},
        { :start_at => DateTime.parse("2016-03-14 11:30 am -0600"), :end_at => DateTime.parse("2016-03-14 1:00 pm -0600")},
        { :start_at => DateTime.parse("2016-03-18 11:30 am -0600"), :end_at => DateTime.parse("2016-03-18 1:00 pm -0600")}
      ]
      expect(builder.generate_event_hashes([tt_hash])).to match_array(expected_events)
    end
  end

  describe "#process_and_validate_event_hashes" do
    let(:builder) { described_class.new(course: course) }

    it "should require start_at and end_at" do
      event_hash = {}
      builder.process_and_validate_event_hashes([event_hash])
      expect(builder.errors).to eq ["start_at and end_at are required"]
    end

    it "should require unique dates" do
      start_at = 1.day.from_now
      end_at = 1.day.from_now + 2.hours
      event_hashes = [
        {:start_at => start_at, :end_at => end_at},
        {:start_at => start_at, :end_at => end_at}
      ]
      builder.process_and_validate_event_hashes(event_hashes)
      expect(builder.errors).to eq ["events (or codes) are not unique"]
    end
  end

  describe "#create_or_update_events" do
    before :once do
      course
      @section = @course.course_sections.create!
      @course_builder = described_class.new(course: @course)
      @section_builder = described_class.new(course: @course, course_section: @section)

      @start_at = 1.day.from_now
      @end_at = 1.day.from_now + 1.hour
      @start_at2 = 2.days.from_now
      @end_at2 = 2.days.from_now + 1.hour
    end

    it "should generate timetable dates for a course" do
      event_hashes = [
        {:start_at => @start_at, :end_at => @end_at},
        {:start_at => @start_at2, :end_at => @end_at2}
      ]
      @course_builder.process_and_validate_event_hashes(event_hashes)
      expect(@course_builder.errors).to be_blank
      @course_builder.create_or_update_events(event_hashes)
      events = @course.calendar_events.for_timetable.to_a
      expect(events.count).to eq 2
      expect(events.map(&:start_at)).to match_array([@start_at, @start_at2])
      expect(events.map(&:end_at)).to match_array([@end_at, @end_at2])
    end

    it "should generate timetable dates for a course section" do
      event_hashes = [
        {:start_at => @start_at, :end_at => @end_at},
        {:start_at => @start_at2, :end_at => @end_at2}
      ]
      @section_builder.process_and_validate_event_hashes(event_hashes)
      expect(@section_builder.errors).to be_blank
      @section_builder.create_or_update_events(event_hashes)

      events = @section.calendar_events.for_timetable.to_a
      expect(events.count).to eq 2
      expect(events.map(&:start_at)).to match_array([@start_at, @start_at2])
      expect(events.map(&:end_at)).to match_array([@end_at, @end_at2])
      expect(events.first.effective_context_code).to eq @course.asset_string
    end

    it "should remove or update existing timetable dates" do
      event_hashes = [
        {:start_at => @start_at, :end_at => @end_at},
        {:start_at => @start_at2, :end_at => @end_at2}
      ]
      @course_builder.process_and_validate_event_hashes(event_hashes)
      expect(@course_builder.errors).to be_blank
      @course_builder.create_or_update_events(event_hashes)

      ce1 = @course.calendar_events.for_timetable.to_a.detect{|ce| ce.start_at == @start_at}
      ce2 = @course.calendar_events.for_timetable.to_a.detect{|ce| ce.start_at == @start_at2}

      location = "under the sea"
      event_hashes2 = [{:start_at => @start_at, :end_at => @end_at, :location_name => location}]
      @course_builder.process_and_validate_event_hashes(event_hashes2)
      expect(@course_builder.errors).to be_blank
      @course_builder.create_or_update_events(event_hashes2)

      expect(ce1.reload.location_name).to eq location
      expect(ce2.reload).to be_deleted
    end
  end
end
