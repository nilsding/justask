class SearchController < ApplicationController
  def search
    if params[:q].nil?
      @results = []
    else
      @results = Answer.search params[:q]
    end
  end
end
