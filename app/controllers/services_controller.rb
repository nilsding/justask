class ServicesController < ApplicationController

  skip_before_action :verify_authenticity_token, :only => :create
  before_action :authenticate_user!

  def index
    @services = current_user.services
  end

  def create
    service = Service.initialize_from_omniauth( omniauth_hash )

    if current_user.services << service
      flash[:success] = 'Successfully added service'
    else
      flash[:error] = 'Could not add service :('
    end

    if origin
      redirect_to origin
    else
      redirect_to services_path
    end
  end

  def failure
    Rails.logger.info "oauth error: #{params.inspect}"
    flash[:error] = 'An error occurred'
    redirect_to services_path
  end

  def destroy
    @service = current_user.services.find(params[:id])
    @service.destroy
    flash[:success] = 'Successfully removed service'
    redirect_to services_path
  end

  private

    def origin
      request.env['omniauth.origin']
    end

    def omniauth_hash
      request.env['omniauth.auth']
    end
end
