module Sidekiq
  module Status
    module WebExtension

      def self.registered(app)
        app.helpers do
          def find_template_with_status(name, *a, &b)
            if !settings.views.is_a?(Array)
              settings.views = Array(settings.views).flatten
            end
            if !settings.views.include?(File.expand_path("../views/", __FILE__))
              settings.views << File.expand_path("../views/", __FILE__)
            end
            settings.views.each { |v| find_template_without_status(v, *a, &b) }
          end
          alias_method_chain :find_template, :status

          def page_status(pageidx=1, page_size=25)
            current_page = pageidx.to_i < 1 ? 1 : pageidx.to_i
            pageidx = current_page - 1
            items = []
            total_size = 0
            starting = pageidx * page_size
            ending = starting + page_size - 1

            Sidekiq.redis do |conn|
              total_size = conn.zcard("statuses")
              items = conn.zrevrange("statuses", starting, ending, :with_scores => true)
            end

            [current_page, total_size, items]
          end
        end

        app.get "/status" do
          @count = (params[:count] || 25).to_i
          (@current_page, @total_size, @messages) = page_status(params[:page], @count)
          @messages = @messages.map { |msg| Sidekiq::Status.load_json(msg[0]) }
          slim :status
        end
      end
    end
  end
end