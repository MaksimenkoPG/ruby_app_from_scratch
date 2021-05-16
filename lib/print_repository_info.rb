module PrintRepositoryInfo
  DEFAULT_URL = 'https://api.github.com/repos/MaksimenkoPG/ruby_app_boilerplate'.freeze

  extend self

  def perform(url:)
    response = Downloader.perform url: url || DEFAULT_URL
    Printer.perform status: response.status, body: response.body
  end
end
