# encoding: UTF-8
class DossiersController < AuthorizedController
  # Authentication
  before_filter :authenticate_user!, except: [:index, :search, :show, :report, :welcome, :sitemap]

  # Responders
  respond_to :html, :js, :json, :xls, :pdf

  # Search
  has_scope :by_character

  # CRUD Actions
  # ============
  def show
    # Set query for highlighting and search form prefill
    @query = params[:search][:text] if params[:search]

    @dossier = Dossier.find(params[:id], include: { containers: [:location, :container_type] })

    authorize! :show, @dossier

    # Tag cloud
    tag_dossiers = @dossier.related_dossiers + [@dossier, @dossier.parent]
    @tags = Tag.filter_tags.where('dossiers.id' => tag_dossiers)

    show! do |format|
      format.xls do
        send_data(@dossier.to_xls,
                  filename: "#{@dossier}.xls",
                  type: 'application/vnd.ms-excel')
      end
    end
  end

  def new
    @dossier = Dossier.new(params[:dossier])
    @dossier.build_default_numbers

    @dossier.containers.build(container_type_code: 'DH')

    new!
  end

  def edit
    @dossier = Dossier.find(params[:id])
    @dossier.build_default_numbers if @dossier.numbers.empty?
    @dossier.prepare_numbers

    edit!
  end

  def create
    create! do |success, _failure|
      success.html do
        flash[:notice] = self.class.helpers.link_to(t('katalog.created', signature: @dossier.signature, title: @dossier.title), dossier_path(@dossier))
        redirect_to new_resource_url
      end
    end
  end

  # Index Actions
  # =============
  def welcome
    redirect_to dossiers_path if user_signed_in?

    @groups = Dossier.group
  end

  def index
    @dossiers = Dossier.by_level(2).accessible_by(current_ability, :index)
    @document_count = Dossier.document_count

    index_excel
  end

  # Sitemap action
  #
  # Provides a sitemap according to http://www.sitemaps.org/protocol.html
  def sitemap
    @dossiers = Dossier.accessible_by(current_ability, :index)
  end
  skip_load_and_authorize_resource only: :sitemap

  # Search
  # ======
  def search
    setup_per_page
    setup_query

    redirect_on_single_result = true

    if !@signature_search
      @dossiers = Dossier.by_text(@query, page: params[:page], per_page: params[:per_page], internal: current_user.present?, skip_topics: (params[:skip_topics] == '1'), include: [:location, :containers])
    else
      @dossiers = apply_scopes(Dossier, params[:search]).by_signature(@query).includes(containers: :location).accessible_by(current_ability, :index).paginate page: params[:page], per_page: params[:per_page]

      redirect_on_single_result = false

      # Alphabetic pagination
      if Topic.alphabetic?(@query)
        @paginated_scope = Dossier.accessible_by(current_ability, :index).by_signature(@query)
      end
    end

    # Do no special handling for single results etc. if JSON is requested
    if request.format.json?
      render json: @dossiers
      return
    end

    # Directly show single match
    if redirect_on_single_result && @dossiers.count == 1
      redirect_to polymorphic_path(@dossiers.first, search: { text: @query })
      # Give spellchecking suggestions
    elsif @dossiers.count == 0
      @spelling_suggestion = SpellChecker.suggestions(@query)
      if @mixed_search
        redirect_to search: { text: '"' + @query + '"' }
      end
    else
      index_excel
    end
  end

  # Report Actions
  # ==============
  def report
    report_name = params[:report_name] || 'overview'
    @report = Report.find_by_name(report_name)

    # Preset parameters
    case report_name
      when 'index'
        @document_count = Dossier.document_count
    end

    # Sanitize and use columns parameter if present
    if params[:columns]
      @report[:columns] = params[:columns].split(',').select { |column| Dossier.columns.include?(column) }
    end

    # Set pagination parameter
    params[:per_page] = @report[:per_page] || 'all'
    @report[:title] ||= report_name
    @is_a_report = true

    setup_per_page
    setup_query

    if !@signature_search
      @dossiers = Dossier.by_text(@query, page: params[:page], per_page: params[:per_page], internal: current_user.present?, include: [:location, :containers, :keywords])
    else
      params[:search].merge!(per_page: @report[:per_page], level: @report[:level])
      @dossiers = apply_scopes(Dossier, params[:search]).by_signature(@query).includes(containers: :location).accessible_by(current_ability, :index).paginate page: params[:page], per_page: params[:per_page]
    end
  end

  # Admin actions
  # =============

  # Dangling relates_to list
  def dangling_relations
    @dossiers = Dossier.with_dangling_relations
  end

  private

  # Filters
  # =======
  def setup_per_page
    params[:per_page] ||= 25

    if params[:per_page] == 'all'
      # Simple hack to simulate all
      params[:per_page] = 1_000_000
    end
  end

  def setup_query
    params[:search] ||= {}
    @query = params[:search][:text].try(:strip) || ''

    signatures, words, sentences = Dossier.split_search_words(@query)
    sentences = sentences.map { |s| s.delete('"') }

    @signature_search = signatures.present? && words.empty? && sentences.empty?
    @mixed_search = signatures.present? && (words.present? || sentences.present?)
    @query_signatures = signatures
    @query_text = (words + sentences).compact.join(' ')
  end

  # Renderers
  # =========
  def index_excel
    index! do |format|
      format.xls do
        if @signature_search
          filename = @dossiers.first.to_s
        else
          filename = t('katalog.search_for', query: @query)
        end

        excel = params[:excel_format] == 'containers' ? Dossier.to_container_xls(@dossiers) : Dossier.to_xls(@dossiers)

        send_data(excel,
                  filename: "#{filename}.xls",
                  type: 'application/vnd.ms-excel')
      end
    end
  end
end
