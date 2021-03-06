module Kracken
  module Controllers
    module JsonApiCompatible
      def self.included(base)
        base.instance_exec do
          before_action :munge_chained_param_ids!
          skip_before_action :verify_authenticity_token

          unless Rails.application.config.consider_all_requests_local
            rescue_from StandardError do |error|
              render_json_error 500, error
            end

            rescue_from ActionController::RoutingError do |error|
              render_json_error 404, error
            end

            if defined? ActiveRecord
              rescue_from ActiveRecord::RecordNotFound do |error|
                render_json_error 404, error
              end
            end
          end

        end
      end

      private

      def munge_chained_param_ids!
        return unless params[:id]
        params[:id] = params[:id].split(/,\s*/)
      end

      def render_json_error(status, error)
        notify_bugsnag(error)
        body = {error: {message: error.message, backtrace: error.backtrace}}
        render status: status, json: body
      end

      def notify_bugsnag(error)
        Bugsnag.notify(error) if defined? BugSnag
      end
    end
  end
end

