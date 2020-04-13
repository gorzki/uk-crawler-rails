class ExportsController < ApplicationController
  def index
    @last_exports = Export.last_ten
  end

  def create
    @service = Crawler.new(crawler_params)
    CrawlerJob.perform_later('crawl', crawler_params) if @service.successfully_logged?
    render_js(:create)
  end

  private

  def crawler_params
    params.permit(:username, :password, :type).to_h.slice(:username, :password, :type).symbolize_keys
  end

  def render_js(template)
    respond_to do |format|
      format.js { render template, layout: false }
    end
  end
end