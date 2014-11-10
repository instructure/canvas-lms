shared_examples_for 'Answer Serializers' do
  # A QuizQuestion of the type the AnswerSerializer deals with.
  #
  # Exports 'qq'.
  #
  # To pass options to the factory, define a mock called `factory_options`
  # somewhere in the test suite. For example:
  #
  # let :factory_options do
  #   {
  #     answer_parser_compatibility: true
  #   }
  # end
  let(:qq) do
    question_type = self.class.described_class.question_type

    factory = method(:"#{question_type}_question_data")
    options = respond_to?(:factory_options) ? factory_options : {}

    # can't test for #arity directly since it might be an optional parameter
    data = factory.parameters.include?([ :opt, :options ]) ?
      factory.call(options) :
      factory.call

    # we'll manually assign an ID of 5 so that we won't have to use variables
    # like "#{question_id}" all over the place, a readability thing that's all
    question_id = data[:id] = 5

    # so, we could just build a new Quiz, but it's unnecessary and this is
    # faster as we only need the #quiz_data set
    quiz = Object.new
    quiz.stubs(:quiz_data).returns [ data ]

    qq = Quizzes::QuizQuestion.new
    qq.id = question_id
    qq.question_data = data
    qq.stubs(:quiz).returns quiz

    qq
  end

  # An AnswerSerializer for the QuizQuestion being tested.
  subject { described_class.new qq }

  context 'serialization' do
    before :each do
      if !respond_to?(:input) && !respond_to?(:inputs)
        raise 'missing :input or :outputs definition'
      elsif !respond_to?(:output) && !respond_to?(:outputs)
        raise 'missing :output or :outputs definition'
      end

      @inputs = respond_to?(:inputs) ? inputs : [ input ]
      @outputs = respond_to?(:outputs) ? outputs : [ output ]
    end

    it '[auto] should serialize' do
      @inputs.each_with_index do |input, index|
        rc = subject.serialize(input)
        expect(rc.error).to be_nil
        expect(rc.answer).to eq @outputs[index]
      end
    end

    it '[auto] should deserialize' do
      @outputs.each_with_index do |output, index|
        input = @inputs[index]

        if respond_to?(:sanitize)
          input = sanitize(input)
        end

        out = subject.deserialize(output)
        expect(out).to eq input
      end
    end
  end
end
