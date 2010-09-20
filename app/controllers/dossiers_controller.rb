require 'ostruct'

class DossiersController < InheritedResources::Base
  # Authentication
  before_filter :authenticate_user!, :except => [:index, :search, :show]
  
  # Responders
  respond_to :html, :js
  
  # Search
  has_scope :by_text, :as => :text
  has_scope :by_signature, :as => :signature
  has_scope :by_title, :as => :title
  has_scope :by_location, :as => :location
  has_scope :by_kind, :as => :kind
  
  # Tags
  has_scope :tagged_with, :as => :tag
  
  # Ordering
  has_scope :order_by, :default => 'signature'
  
  # GET /dossiers
  # GET /dossiers.xml
  def index
    params[:dossier] ||= {}

    # Support new_signature
    if @new_signature = params[:dossier][:order_by] == "new_signature"
      params[:dossier][:order_by] ||= 'new_signature'
    end
    
    @dossiers = apply_scopes(Dossier, params[:dossier]).where("type IN ('TopicGroup', 'Topic')")
    
    index!
  end

  # GET /dossiers/search
  # GET /dossiers/search.xml
  def search
    params[:per_page] ||= 25
    
    params[:search] ||= {}
    params[:search][:text] ||= (params[:search][:query] || params[:search][:signature])
    @query = params[:search][:text]
    
    if @query.present?
      @dossiers = Dossier.by_text(params[:search][:text], :page => params[:page], :per_page => params[:per_page])
    else
      @dossiers = apply_scopes(Dossier, params[:search]).paginate :page => params[:page], :per_page => params[:per_page]
    end
    
    # Drop nil results by stray full text search matches
    @dossiers.compact!
    
    index!
  end
end
