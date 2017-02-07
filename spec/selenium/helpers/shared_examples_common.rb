module SharedExamplesCommon
  def self.included(mod)
    mod.singleton_class.include(ClassMethods)
  end

  module ClassMethods
    # For use with choosing TestRail test id in shared specs based on context.
    #
    # usage:
    #   pick_test_id(context, option1: <id1>, option2: <id2> [, option3: <id3])
    #
    # example:
    #   it "should manually change a course quota", priority: "1",
    #     test_id: pick_test_id(account_type, sub_account: 250004, root_account: 251034) do
    #
    def pick_test_id(context, opts = {})
      if opts.empty? || !opts.key?(context)
        raise("Error: Invalid context for test id")
      end
      opts[context]
    end

    # For use with choosing example priority in shared specs based on context.
    #
    # usage:
    #   pick_priority(context, option1: <id1>, option2: <id2> [, option3: <id3])
    #
    # example:
    #   it 'should persist',
    #     test_id: pick_test_id(context, student: "591860", teacher: "592108",
    #                                    admin: "592119", ta: "592130"),
    #     priority: pick_priority(context, student: "1", teacher: "1", admin: "2", ta: "2") do
    #
    def pick_priority(context, opts ={})
      if opts.empty? || !opts.key?(context)
        raise("Error: Invalid context for test id")
      end
      opts[context]
    end
  end
end
