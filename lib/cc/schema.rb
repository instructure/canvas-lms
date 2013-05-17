module CC
  class Schema

    XSD_DIRECTORY = "lib/cc/xsd"
    REGEX = /\.xsd$/

    def self.for_version(version)
      return nil unless whitelist.include?(version)
      Rails.root + "#{XSD_DIRECTORY}/#{version}.xsd"
    end


    def self.whitelist
      @whitelist ||= Dir.entries(XSD_DIRECTORY).inject([]) do |memo, entry|
        memo << entry.gsub(REGEX, '') if entry =~ REGEX
        memo
      end
    end

  end
end
