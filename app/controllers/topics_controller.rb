class TopicsController < AuthorizedController
  # Authentication
  before_filter :authenticate_user!, :except => [:index, :show, :sub_topics]

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

  def index
    redirect_to dossiers_path
  end
  
  def create
    create! do |format|
      format.html do
        flash[:notice] = t('katalog.created')
        redirect_to new_resource_url
      end
    end
  end
  
  def sub_topics 
    @topics = Topic.find(params[:id]).direct_children
    
    respond_with @topics do |format|
      format.html { render :layout => false }
    end
  end
end
