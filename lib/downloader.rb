require 'faraday'

module Downloader
  extend self

  def perform(url:)
    Faraday.get(url)
  end
end
