desc 'Print repo info, usage: rake print_repository_info repository_url=repository_url'
task print_repository_info: :environment do
  PrintRepositoryInfo.perform url: ENV['repository_url']
end
