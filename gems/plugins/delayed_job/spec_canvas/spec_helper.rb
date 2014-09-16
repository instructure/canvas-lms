require File.expand_path(File.dirname(__FILE__) + '/../../../../spec/spec_helper')

# Purely useful for test cases...
class Story < ActiveRecord::Base
  def tell; text; end
  def whatever(n, _); tell*n; end
  def whatever_else(n, _); tell*n; end

  handle_asynchronously :whatever
  handle_asynchronously_with_queue :whatever_else, "testqueue"
end

class StoryReader
  def read(story)
    "Epilog: #{story.tell}"
  end

  def self.reverse(str)
    str.reverse
  end
end

module MyReverser
  def self.reverse(str)
    str.reverse
  end
end

require File.expand_path('../sample_jobs', __FILE__)
require File.expand_path('../shared_jobs_specs', __FILE__)
