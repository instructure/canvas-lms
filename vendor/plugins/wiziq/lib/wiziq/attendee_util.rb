module Wiziq
  class AttendeeUtil
    def initialize
      @node = Nokogiri::XML.fragment("<attendee_list/>").child
    end

    def add_attendee(attendee_id, screen_name)
      attendee = @node.add_child('<attendee/>').first
      attendee.add_child('<attendee_id/>').first.content = attendee_id
      attendee.add_child('<screen_name/>').first.content = screen_name
      true
    end

    def get_attendee_xml
      @node.to_xml
    end
  end
end
