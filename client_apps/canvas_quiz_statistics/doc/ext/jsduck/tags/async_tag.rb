require "jsduck/tag/tag"

class Async < JsDuck::Tag::BooleanTag
  def initialize
    @pattern = "async"
    @signature = { long: 'asynchronous', short: 'async' }
    super
  end
end