module DataFixup
  class FixBlankCourseSectionNames

    def self.time_format(section)
      Time.use_zone(section.root_account.try(:default_time_zone) || 'UTC') do
        section.created_at.strftime("%Y-%m-%d").to_s
      end
    end

    def self.run
      CourseSection.where("name IS NULL OR name = ' ' OR name = ''").find_each do |section|
        if section.default_section
          section.name = section.course.name
        else
          section.name = "#{section.course.name} #{time_format(section)}"
        end
        section.save!
      end
    end

  end
end
