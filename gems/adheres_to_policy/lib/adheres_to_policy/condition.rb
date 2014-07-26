module AdheresToPolicy
  class Condition
    attr_reader :given, :rights

    def initialize(given)
      @given = given
      @rights = Set.new
    end

    def can(right, *rights)
      @rights.merge([right, rights].flatten)
    end
  end
end