# encoding: UTF-8

module DossiersHelper
  def link_to_tag_filter(name, options = {})
    query = [@query, name].compact.join(' ')
    link_to(name, search_dossiers_path(search: { text: query }), options)
  end

  def link_to_keyword(keyword, options = {})
    link_to(keyword, search_dossiers_path(search: { text: keyword }), options)
  end

  def link_to_relation(relation)
    dossier = Dossier.where(title: relation).first
    if dossier
      link_to(relation, dossier)
    else
      link_to(relation, search_dossiers_url(search: { text: '"' + relation + '"' }))
    end
  end

  def availability_text(availability)
    title = t(availability, scope: 'katalog.availability.title')

    text = content_tag 'span', class: "availability icon-availability_#{availability}-text", title: title do
      title
    end

    text
  end

  def availability_notes(dossier)
    # Collect availabilities
    availabilities = availabilities(dossier)
    notes = ''
    notes += availability_text('intern') if availabilities.include?('intern')
    notes += availability_text('inactive') if availabilities.include?('inactive')
    notes += availability_text('warning') if waiting_for?(dossier)

    notes.html_safe
  end

  def waiting_for?(dossier)
    availabilities = availabilities(dossier)

    availabilities.include?('wait') ? true : false
  end

  def url_for_topic(topic)
    if is_edit_report?
      edit_batch_edit_dossier_numbers_path(search: { text: topic.signature })
    else
      search_dossiers_path(search: { text: topic.signature })
    end
  end

  def link_to_topic(topic, options = {})
    link_to(topic, url_for_topic(topic), options)
  end

  # Best title based on query
  #
  # @returns
  #   * topic title if a single signature is searched for
  #   * annotated query string otherwise
  def search_title
    if @signature_search && @query_signatures.count == 1
      if topic = Topic.by_signature(@query_signatures.first).first
        return topic
      end
    end

    t('katalog.search_for', query: @query)
  end

  # Reports
  # =======
  def show_header_for_report(column)
    case column
      when :document_count
        @document_count ? t('katalog.total_count', count: number_with_delimiter(@document_count)) : t_attr(:document_count, Dossier)
      else
        t_attr(column.to_s, Dossier)
    end
  end

  def show_column_for_report(dossier, column, for_pdf = false)
    case column.to_s
      when 'title'
        for_pdf == true ? link_to(dossier.title, polymorphic_url(dossier)) : link_to(dossier.title, dossier, 'data-href-container' => 'tr')
      when 'container_type'
        dossier.container_types.collect(&:code).join(', ')
      when 'location'
        dossier.locations.collect(&:code).join(', ')
      when 'document_count'
        number_with_delimiter(dossier.document_count)
      when 'keywords'
        dossier.keywords.join(', ')
      else
        dossier.send(column).to_s
    end
  end

  # JS Highlighting
  def highlight_words(query, element = 'dossiers')
    return unless query.present?

    signatures, words, sentences = Dossier.split_search_words(query)
    # Highlight all alternatives for words
    words = SphinxAdmin.extend_words(words.flatten)

    content = ActiveSupport::SafeBuffer.new
    for word in (words + sentences)
      content += javascript_tag "$('##{element}').highlight('#{escape_javascript(word)}', 'match')"
    end

    content
  end

  def is_edit_report?
    @search_path.present?
  end

  def split_decades(numbers)
    splitted_numbers = []
    decades = (199..(DateTime.now.year.to_s[0..2].to_i))

    decades.each do |decade|
      splitted_numbers << numbers.find_all { |n| n.period.include?(decade.to_s) }
    end

    splitted_numbers.reject { |a| a.join.strip.length == 0 }
  end

  def default_periods_collection
    DossierNumber.default_periods.collect do |d|
      from = d[:from].present? ? d[:from].strftime('%y') : ''
      to = d[:to].strftime('%y')
      label = from.eql?(to) ? "#{d[:to].year}" : "#{from}-#{to}"

      [label, d[:to].year] if d[:to]
    end
  end

  # Adds to all links the attribute target with '_blank' as value.
  def target_blank(text)
    html_content = Nokogiri::HTML(text)

    (html_content / 'a').each { |a| a.attributes['target'] = '_blank' }

    html_content
  end

  private

  def availabilities(dossier)
    dossier.availability.compact
  end
end
