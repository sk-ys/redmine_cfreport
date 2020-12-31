module RedmineCFReport
  module Hooks
    class ViewReportsIssueReportSplitContentLeftHook < Redmine::Hook::ViewListener
      render_on :view_reports_issue_report_split_content_left, partial: 'issue_report_with_cfreport'
    end
  end
end
