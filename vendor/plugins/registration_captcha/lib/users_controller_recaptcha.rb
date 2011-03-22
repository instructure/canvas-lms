UsersController.class_eval do
  alias :create_original :create
  def create
    @user = User.new(params[:user])
    recap = Canvas::Plugin.find('registration_form_recaptcha')
    if recap && !recap.settings[:public_key].blank? && !recap.settings[:private_key].blank?
      @user = nil if verify_recaptcha(:model => @user, :private_key => recap.settings[:private_key])
    end
    create_original
  end
end
