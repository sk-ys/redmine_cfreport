require File.expand_path('../lib/redmine_cfreport', __FILE__)

ActiveSupport::Reloader.to_prepare do
  paths = '/lib/redmine_cfreport/{patches/*_patch,hooks/*_hook}.rb'
  Dir.glob(File.dirname(__FILE__) + paths).each do |file|
    require_dependency file
  end
end

Redmine::Plugin.register :redmine_cfreport do
  name 'Redmine CFReport plugin'
  author 'sk-ys'
  description 'This is a plugin for Redmine'
  version '0.0.5'
  url 'https://github.com/sk-ys/redmine_cfreport'
  author_url 'https://github.com/sk-ys'

  settings \
    default:  {
      supported_field_format: ['enumeration', 'list', 'bool', 'string'],
      filtering: 0,
      left_items: [],
      right_items: [],
    },
    partial: 'cfreport/settings'
end
