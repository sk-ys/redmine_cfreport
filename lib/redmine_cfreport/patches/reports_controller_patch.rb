require 'ostruct'

module RedmineCFReport
  module Patches
    module ReportsControllerPatch
      def self.included(base)
        base.send :include, InstanceMethods
        base.class_eval do
          alias_method :issue_report_without_cfreport, :issue_report
          alias_method :issue_report, :issue_report_with_cfreport

          alias_method :issue_report_details_without_cfreport, :issue_report_details
          alias_method :issue_report_details, :issue_report_details_with_cfreport
        end
      end

      module InstanceMethods
        def count_and_group_by_cf(cf, options)
          bool_values = [l(:general_text_no), l(:general_text_yes)]

          Issue.
            visible(User.current, :project => options[:project], :with_subprojects => options[:with_subprojects]).
            joins(:status, :custom_values).
            group(:status_id, :is_closed, :custom_field_id, :value).
            count.
            reject{|columns, total| columns[2] != cf.id}.
            map do |columns, total|
              status_id, is_closed, cf_id, cf_value = columns
              is_closed = ['t', 'true', '1'].include?(is_closed.to_s)

              if cf.field_format == 'bool'
                cf_value = bool_values[cf_value.to_i] if cf_value != ''
              end

              {
                'status_id' => status_id.to_s,
                'closed' => is_closed,
                'cf_value' => cf_value.to_s,
                'total' => total.to_s
              }
            end
        end

        def cf_values(cf, options)
          case cf.field_format
          when 'enumeration'
            CustomFieldEnumeration.where(custom_field_id: cf.id, active: true).order(:position)
          when 'list'
            cf.possible_values.map {|v| OpenStruct.new({id:v, name:v})}
          when 'bool'
            [
              OpenStruct.new({id:1, name:l(:general_text_yes)}),
              OpenStruct.new({id:0, name:l(:general_text_no)})
            ]
          when 'string'
            Issue.
              visible(User.current, :project => options[:project], :with_subprojects => options[:with_subprojects]).
              joins(:custom_values).map {|i| i.custom_values.find_by(custom_field_id: cf.id)&.value}.
              compact.reject {|c| c.empty?}.uniq.sort.
              map {|v| OpenStruct.new({id:v, name:v})}
          else
            # TODO:
          end
        end

        def cfreport_data(cf, options)
          rows = cf_values(cf, options)
          data = count_and_group_by_cf(cf, options)

          if cf.field_format == 'enumeration'
            data.each do |d|
              d["cf_#{cf.id}"] = d['cf_value']
              d['cf_value'] = rows.find {|r| r.id == d["cf_#{cf.id}"]}&.name
            end
          else
            data.each do |d|
              d["cf_#{cf.id}"] = rows.find {|r| r.name == d['cf_value']}&.id
            end
          end

          [rows, data]
        end

        def issue_report_with_cfreport
          with_subprojects = Setting.display_subprojects_issues?

          supported_field_format = ['enumeration', 'list', 'bool', 'string']

          @custom_fields = @project.issue_custom_fields.where(field_format: supported_field_format)
          @custom_field_values = {}
          @issues_by_custom_field = {}

          @custom_fields.each do |cf|
            @custom_field_values[cf.id], @issues_by_custom_field[cf.id] = cfreport_data(cf, project: @project, with_subprojects: with_subprojects)
          end

          issue_report_without_cfreport
        end

        def issue_report_details_with_cfreport
          if /^cf_\d+$/.match(params[:detail])
            with_subprojects = Setting.display_subprojects_issues?
            cf_id = /^cf_(\d+)$/.match(params[:detail])[1]
            cf = CustomField.find(cf_id)

            @rows, @data = cfreport_data(cf, project: @project, with_subprojects: with_subprojects)

            @field = "cf_#{cf.id}"
            @report_title = cf.name
          else
            issue_report_details_without_cfreport
          end
        end
      end
    end
  end
end

base = ReportsController
patch = RedmineCFReport::Patches::ReportsControllerPatch
base.send(:include, patch) unless base.included_modules.include?(patch)
