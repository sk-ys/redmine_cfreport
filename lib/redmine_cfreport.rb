module RedmineCFReport
  def self.settings
    ActionController::Parameters.new(Setting[:plugin_redmine_cfreport])
  end
end
