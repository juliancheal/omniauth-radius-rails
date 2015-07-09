module Kracken
  module JsonApi
    class PublicExceptions
      attr_reader :app
      def initialize(app)
        @app = app
      end

      def call(env)
        app.call(env)
      rescue Exception => exception
        raise exception unless JsonApi.has_path?(JsonApi::Request.new(env))
        render_json_error(ExceptionWrapper.new(env, exception))
      end

      if Rails.env.production?
        def additional_details(error)
          {}
        end
      else
        def additional_details(error)
          {
            backtrace: error.backtrace,
          }
        end
      end

      def show_error_details?(wrapper)
        wrapper.is_details_exception? ||
          ( Rails.application.config.consider_all_requests_local &&
            wrapper.status_code == 500)
      end

      def error_as_json(wrapper)
        return {} unless show_error_details?(wrapper)
        error = wrapper.exception
        {
          # "`detail`" - A human-readable explanation specific to this occurrence
          #              of the problem.
          detail: error.message,
          # Additional members **MAY** be specified within error objects.
        }.merge(additional_details(error))
      end

      def numeric_code(status)
        case status
        when Symbol
          code = Rack::Utils::SYMBOL_TO_STATUS_CODE[status]
        when Fixnum
          code = status
        when String
          code = status.to_i
          code = nil if code == 0
        end
        raise ArgumentError, "Invalid response type #{status.inspect}" if code.nil?
        code
      end

      def render_json_error(wrapper)
        body = json_body(wrapper)
        [ wrapper.status_code, headers(body), [body] ]
      end

      def json_body(wrapper)
        # Error objects are specialized resource objects that **MAY** be returned
        # in a response to provide additional information about problems
        # encountered while performing an operation. Error objects **SHOULD** be
        # returned as a collection keyed by "`errors`" in the top level of a JSON
        # API document, and **SHOULD NOT** be returned with any other top level
        # resources.
        {
          errors: [
            status_code_as_json(wrapper.status_code).merge(error_as_json(wrapper))
          ]
        }.to_json
      end

      def headers(body)
        {
          'Content-Type'   => "application/json; charset=#{ActionDispatch::Response.default_charset}",
          'Content-Length' => body.bytesize.to_s
        }
      end

      def status_code_as_json(status)
        code = numeric_code(status)
        title = Rack::Utils::HTTP_STATUS_CODES.fetch(code) {
          raise ArgumentError, "Invalid response type #{status}"
        }
        {
          # "`status`" - The HTTP status code applicable to this problem, expressed
          #              as a string value.
          status: code.to_s,
          # "`title`" - A short, human-readable summary of the problem. It **SHOULD
          #             NOT** change from occurrence to occurrence of the problem,
          #             except for purposes of localization.
          title: title,
        }
      end
    end
  end
end