class Oauth::ApplicationsController < Doorkeeper::ApplicationsController
  before_filter :authenticate_user!
  before_filter :app_owner!, only: %i(show update)

  def index
    @applications = current_user.oauth_applications
  end

  def create
    @application = Doorkeeper::Application.new(application_params)
    @application.owner = current_user if Doorkeeper.configuration.confirm_application_owner?
    if @application.save
      flash[:notice] = I18n.t(:notice, :scope => [:doorkeeper, :flash, :applications, :create])
      redirect_to oauth_application_path(@application)
    else
      render :new
    end
  end

  protected

  def app_owner!
    raise ActiveRecord::RecordNotFound unless @application.owner == current_user
  end

end