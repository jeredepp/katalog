class TopicsController < InheritedResources::Base
  # Authentication
  before_filter :authenticate_user!, :except => [:index, :show]

  protected
  def collection
    @topics ||= end_of_association_chain.paginate(:page => params[:page])
  end

  # Actions
  public
  def update
    @topic = Topic.find(params[:id])
    if params[:update_signature]
      @topic.update_signature(params[:topic][:signature])
    end
    update!
  end
end
