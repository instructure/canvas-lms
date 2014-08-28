shared_examples_for 'Textual Answer Serializers' do
  MaxLength = Quizzes::QuizQuestion::AnswerSerializers::Util::MaxTextualAnswerLength

  it '[auto] should reject an answer that is too long' do
    input = 'a' * (MaxLength+1)
    input = format(input) if respond_to?(:format)

    rc = subject.serialize(input)
    rc.valid?.should be_false
    rc.error.should match(/too long/i)
  end

  it '[auto] should reject a textual answer that is not a String' do
    [ nil, [], {} ].each do |bad_input|
      bad_input = format(bad_input) if respond_to?(:format)

      rc = subject.serialize(bad_input)
      rc.valid?.should be_false
      rc.error.should match(/must be of type string/i)
    end
  end
end
