module AdheresToPolicy
  class Condition
    attr_reader :given, :rights, :parent

    def initialize(given, parent = nil)
      @parent = parent
      @given = given
      @rights = Set.new
    end

    def can(right, *rights)
      @rights.merge([right, rights].flatten)
    end

    # Internal: Checks whether this condition currently holds for the specified
    # object.
    #
    # object    - The object to check
    # user      - The user passed to the condition to determine if they pass the
    #             condition.
    # session   - The session passed to the condition to determine if the user
    #             passes the condition.
    #
    # Examples
    #
    #   Condition.new(->(user) { true }).applies?(some_object, user, session)
    #   # => true
    #
    #   Condition.new(->(user, session){ false }).applies?(some_object, user, session)
    #   # => false
    #
    # Returns true or false on whether the user passes the condition.
    def applies?(object, user, session)
      return false if parent && !parent.applies?(object, user, session)

      if given.arity == 1
        object.instance_exec(user, &given)
      else
        object.instance_exec(user, session, &given)
      end
    end
  end
end