class CrawlerJob < ApplicationJob
  queue_as :default

  def perform(action, **args)
    send(action, args)
  end
  
  private

  def crawl(username:, password:, type:)
    service = Crawler.new(username: username, password: password, type: type)
    service.call ? success_broadcast : fail_broadcast
  end

  def success_broadcast
    ActionCable.server.broadcast(
      "guest_channel",
      { 
        msg: "Successfully fetched data. Last exports updated",
        target: '#js-last-exports',
        partial: render_last_exports,
        type: :crawler
      }
     )
  end

  def fail_broadcast
    ActionCable.server.broadcast(
      "guest_channel",
      { 
        msg: "Something went wrong... CSV was not created.",
        type: :fail
      }
    )
  end

  def render_last_exports
    ApplicationController.render(
      partial: 'exports/index/last_exports',
      locals: { last_exports: Export.last_ten }
    )
  end
end