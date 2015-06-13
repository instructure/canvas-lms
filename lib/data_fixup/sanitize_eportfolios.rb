require 'sanitize'

module DataFixup
  module SanitizeEportfolios
    def self.run
      config = CanvasSanitize::SANITIZE
      EportfolioEntry.
        where("content LIKE '%rich\_text%' OR content LIKE '%html%'").
        find_each do |entry|
          next unless entry.content.is_a?(Array)
          entry.content.each do |obj|
            next unless obj.is_a?(Hash)
            next unless ['rich_text', 'html'].include?(obj[:section_type])
            obj[:content] = Sanitize.clean(obj[:content] || '', config).strip
          end
          entry.save!
      end
    end
  end
end
