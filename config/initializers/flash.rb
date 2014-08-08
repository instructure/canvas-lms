if CANVAS_RAILS3

class ActionController::Flash::FlashHash < Hash
  def to_rails3
    result = ActionDispatch::Flash::FlashHash.new
    result.instance_variable_set(:@now, @now)
    result.instance_variable_set(:@flashes, to_h)
    result.instance_variable_set(:@used, @used.select { |k, v| v }.keys.to_set)
    result
  end
end

class ActionDispatch::Flash
  def call(env)
    if (session = env['rack.session']) && (flash = session['flash'])
      if flash.is_a?(ActionController::Flash::FlashHash)
        session['flash'] = flash = flash.to_rails3
      end
      flash.sweep
    end

    @app.call(env)
  ensure
    session    = env['rack.session'] || {}
    flash_hash = env[KEY]

    if flash_hash
      if !flash_hash.empty? || session.key?('flash')
        session["flash"] = flash_hash
        new_hash = flash_hash.dup
      else
        new_hash = flash_hash
      end

      env[KEY] = new_hash
    end

    if session.key?('flash') && session['flash'].empty?
      session.delete('flash')
    end
  end
end

else

module ActionDispatch
  class Flash
    class FlashHash
      def to_rails2
        result = ActionController::Flash::FlashHash.new
        result.instance_variable_set(:@now, @now)
        result.replace(@flashes)
        result.instance_variable_set(:@used, @used.inject({}) { |h, v| h[v] = true; h})
        result
      end
    end
  end
end

ActionController::Flash::InstanceMethods.class_eval do
  def flash #:doc:
    if !defined?(@_flash)
      @_flash = session["flash"] || ActionController::Flash::FlashHash.new
      if @_flash.is_a?(ActionDispatch::Flash::FlashHash)
        @_flash = @_flash.to_rails2
      end
      @_flash.sweep
    end

    @_flash
  end
end

end
