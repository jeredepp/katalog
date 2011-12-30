class QueryTopic < Topic
  def dossiers
    dossiers = Dossier.by_text(self.query) if self.query.present?

    dossiers.compact.empty? ? nil : dossiers
  end

  def document_count
    0
  end
end