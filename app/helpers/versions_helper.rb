module VersionsHelper
  def change_type(previous, current)
    if previous == current
      return "unchanged"
    elsif previous.nil?
      return "added"
    elsif current.nil?
      return "removed"
    else
      return "changed"
    end
  end
  
  def version_title(version = nil)
    active_item(version).to_s
  end

  def user_email(version)
    User.find(version.whodunnit).email if version.whodunnit
  end

  def action(version)
    t(version.event, :scope => "katalog.versions.actions")
  end

  def active_item(version)
    # Fast track if item currently exists
    active_item = version.item
    return active_item if active_item

    # Take latest and reify
    latest_version = Version.subsequent(version).last || version

    return latest_version.reify
  end
  
  def active_main_item(version)
    item = active_item(version)
    
    case item.class.name
    when 'DossierNumber'
      return item.dossier
    else
      return item
    end
  end
end
