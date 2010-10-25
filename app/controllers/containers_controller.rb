class ContainersController < InheritedResources::Base
  # Authentication
  before_filter :authenticate_user!, :except => [:index, :search, :show]
  
  # Responders
  respond_to :html, :js
end