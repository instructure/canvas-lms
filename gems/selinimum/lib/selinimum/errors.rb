module Selinimum
  class SelinimumError < StandardError; end
  class UnknownDependentsError < SelinimumError; end
  class TooManyDependentsError < SelinimumError; end
end
