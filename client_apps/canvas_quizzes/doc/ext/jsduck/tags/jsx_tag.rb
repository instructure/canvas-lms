require "jsduck/tag/tag"
require "jsduck/tag/boolean_tag"

module JsDuck::Tag
  class Jsx < Ignore
    def initialize
      @tagname = :ignore
      @pattern = "jsx"
    end
  end
end