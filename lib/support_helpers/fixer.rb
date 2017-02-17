module SupportHelpers
  class Fixer
    attr_reader :job_id

    def initialize(email, after_time = nil)
      @email = email
      @start_time = 0
      @after_time = after_time || 2.months.ago
      @job_id = Time.now.to_i + Random.rand(1000) # just need something unique
      @prefix ||= nil
    end

    def monitor_and_fix
      @start_time = Time.now

      fix # actually do it

      notify "Success", success_message
    rescue => error
      notify "Error", error_message(error)
      raise error
    end

    def fix
      raise "#{self.class.name} must implement #fix"
    end

    def fixer_name
      [@prefix, self.class.name.demodulize, "##{job_id}"].compact.join(' ')
    end

    private

    def elapsed_time
      return 0 unless @start_time
      (Time.now - @start_time).to_i
    end

    def success_message
      "#{fixer_name} done in #{elapsed_time} seconds!"
    end

    def error_message(error)
      message = error.try(:message)
      backtrace = error.try(:backtrace).try(:join, "<br/>")
      "#{fixer_name} failed because #{message}<br/><br/>#{backtrace}"
    end

    def notify(status, message)
      m = Message.new(
        to: @email,
        from: mail_from,
        subject: mail_subject(status),
        body: message,
        delay_for: 0
      )
      Mailer.create_message(m).deliver rescue nil # omg! just ignore delivery failures
    end

    def mail_from
      'supporthelperscript@instructure.com'
    end

    def mail_subject(status)
      "#{@prefix}Fixer #{status}"
    end
  end
end
