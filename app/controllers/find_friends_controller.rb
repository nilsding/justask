class FindFriendsController < ApplicationController
  before_filter :authenticate_user!

  def index
    twitter = current_user.services.where(type: 'Services::Twitter').first
    if twitter
      # TODO: actually insert some code here
    end
  end
end
