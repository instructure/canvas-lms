module Factories
  def conversation(*users)
    options = users.last.is_a?(Hash) ? users.pop : {}
    @conversation = (options.delete(:sender) || @me || users.shift).initiate_conversation(users, options.delete(:private), options)

    # if the "body" hash is passed in, use that for the message body
    if !options[:body].nil?
      @message = @conversation.add_message(options[:body].to_s)
    else
      @message = @conversation.add_message('test')
    end

    @conversation.update_attributes(options)
    @conversation.reload
  end
end
