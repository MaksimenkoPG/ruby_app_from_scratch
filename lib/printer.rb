module Printer
  extend self

  def perform(status:, body:)
    puts status
    puts body
  end
end
