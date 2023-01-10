module RedmineCfreport
  module Patches
    module ReportsHelperPatch
      def self.included(base)
        base.send :include, InstanceMethods
        base.class_eval do
          alias_method :aggregate_path_without_redmine_cfreport, :aggregate_path
          alias_method :aggregate_path, :aggregate_path_with_redmine_cfreport
        end
      end

      module InstanceMethods
        def aggregate_path_with_redmine_cfreport(project, field, row, options={})
          if /^cf_\d+$/.match(field)
            cf_id = /^cf_(\d+)$/.match(field)[1]
            cf = CustomField.find(cf_id)
            unless cf.is_filter?
              return 'javascript:;'
            end
          end
          aggregate_path_without_redmine_cfreport(project, field, row, options)
        end
      end
    end
  end
end

base = ReportsHelper
patch = RedmineCfreport::Patches::ReportsHelperPatch
base.send(:include, patch) unless base.included_modules.include?(patch)
