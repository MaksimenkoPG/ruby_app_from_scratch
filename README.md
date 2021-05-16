# Boilerplate of a simple ruby application
Hi folks!
Today we're going to build a simple ruby application from scratch.
With Bundler, Rake, handmade console & autoload of code.
This kind of application can be useful when you want to make something bigger than a simple script and smaller than an application based on the framework.
Usually, I use this kind of application for testing API endpoints.
It helps me to organize all my code and avoid DRY.
This application will use [Github API](https://docs.github.com/en/rest/reference/repos#get-a-repository) to get information about the repository and print it to STDOUT.
All code you may find in my repository [https://github.com/MaksimenkoPG/ruby_app_from_scratch](https://github.com/MaksimenkoPG/ruby_app_from_scratch).

## Init & install Bundler
First of all, let's create a folder for our application.
```bash
mkdir ruby_app_from_scratch && cd ruby_app_from_scratch
```
After that, let's install Ruby. In this article, I use **ruby-2.7.3**.
For development I prefer RVM, but you can your favorite ruby manager, like asdf or rbenv.
In the next step, we will install Bundler. It will help us to organize dependencies for the application. Of course, you may manage your dependencies via **gem install** but, in the future, this approach becomes a mess.
Let's install and init it.
```bash
gem install bundler -v 2.2.17 && bundler init
```
In this example, I use Bundler with version **2.2.17**.

## Install Faraday
We will use Faraday as an HTTP client. Let's add it to the Gemfile.
```ruby
# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gem 'faraday', '1.4.1'
```
And install it.
```bash
bundle install
```
Now, we can use Faraday in our application, in IRB, for example.
```ruby
# irb
require 'faraday'
url = 'https://api.github.com/repos/MaksimenkoPG/ruby_app_boilerplate'
response = Faraday.get(url)
puts response.status
puts response.body
```

## Set up Rake
Generally, we've done tasks for downloading and printing, but, use this code in this state a little bit uncomfortable. The CLI will make interaction with the application more comfortable.
As a CLI, I've chosen [Rake](https://github.com/ruby/rake). It has a pretty simple setup for our purpose.
Add it to the Gemfile.
```ruby
# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gem 'faraday', '1.4.1'
gem 'rake', '13.0.3'
```
And install it.
```bash
bundle install
```
To set up Rake we have to add Rakefile in the root folder of our application with the following content.
```ruby
Dir.glob('lib/tasks/**/*.rake').each { |file_path| load file_path }
```
This code loads all tasks from the **lib/tasks** folder.
Let's create this folder and add our rake task to it.
```bash
mkdir -p lib/tasks
```
```ruby
# lib/tasks/print_repository_info.rake
require 'faraday'

desc 'Print repo info, usage: rake print_repository_info repository_url=repository_url'
task :print_repository_info do
  default_url = 'https://api.github.com/repos/MaksimenkoPG/ruby_app_boilerplate'

  url = ENV['repository_url'] || default_url
  response = Faraday.get(url)
  puts response.status
  puts response.body
end
```
Now, the task should be on the list of rake tasks.
```bash
rake -T
=> rake print_repository_info  # Print repo info, usage: rake print_repository_info repository_url=repository_url
```
And it has the same functionality that we tasted in IRB.
## Split application to components
If we look at our rake task a little bit closer we will see a few parts/layers.
- First of all, it is a common operation, that consists of downloading and printing.
Also, it can perform some initial logic before the operation will be done.
- The second one is the downloader.
That component downloads content from the network.
- And the last one is the printer.
This component gets output from the downloader and prints it.

Let's split our rake task for that components.
```ruby
# lib/print_repository_info.rb
module PrintRepositoryInfo
  DEFAULT_URL = 'https://api.github.com/repos/MaksimenkoPG/ruby_app_boilerplate'.freeze

  extend self

  def perform(url:)
    response = Downloader.perform url: url || DEFAULT_URL
    Printer.perform status: response.status, body: response.body
  end
end
```
```ruby
# lib/downloader.rb
require 'faraday'

module Downloader
  extend self

  def perform(url:)
    Faraday.get(url)
  end
end
```
```ruby
# lib/printer.rb
module Printer
  extend self

  def perform(status:, body:)
    puts status
    puts body
  end
end
```
```ruby
# lib/tasks/print_repository_info.rake
desc 'Print repo info, usage: rake print_repository_info repository_url=repository_url'
task :print_repository_info do
  PrintRepositoryInfo.perform url: ENV['repository_url']
end
```
At this point, if we try to run our rake task we will get an error.
```bash
rake aborted!
NameError: uninitialized constant PrintRepositoryInfo
lib/tasks/print_repository_info.rake:3:in `block in <top (required)>'
```
It is obvious because our rake task doesn't know about other components of our system.

## Set up Application with code autoload 
One of the ways is to inject our components via require_relative, like `require_relative '../print_repository_info'`.
Another way is to preload our environment, all our *.rb files from the lib folder.
To do this we need to create a helper module that will load for up all our environment.
Let's create the **config** folder.
```bash
mkdir config
```
And create in this folder **application.rb** file with the following content.
```ruby
# config/application.rb
require_relative 'boot'

module Application
  extend self

  def root
    @root ||= File.dirname(File.expand_path(__dir__))
  end

  def load_libs
    Dir.glob(File.join(root, 'lib/**/*.rb')).sort.each { |fname| load(fname) }
  end
end

Application.load_libs
```
Also, we will create **boot.rb** in the same folder and inject it into our application.
```ruby
# config/boot.rb
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
```
The same structure, I mean application.rb + boot.rb, you can meet in any modern Rails application.
**boot.rb** is just loads Bundler environment for us.
Now, we should have an access to our components out from the IRB console.
```ruby
# irb
require_relative 'config/application'
PrintRepositoryInfo.perform(url: 'https://api.github.com/repos/rails/rails')
```
## Set up environment for rake tasks
The next step is to add access to our components for the rake task.
Maybe, you've met the following code in your rake tasks in the Rails application.
```ruby
desc 'Foo'
task foo: :environment do
  ...
end
```
In this case, **environment** is just another rake task that has to be done before the current task.
Let's add this task to the Rakefile.
```ruby
# Rakefile
task :environment do
  require_relative 'config/application'
end

Dir.glob('lib/tasks/**/*.rake').each { |file_path| load file_path }
```
And change our rake task.
```ruby
# lib/tasks/print_repository_info.rake
desc 'Print repo info, usage: rake print_repository_info repository_url=repository_url'
task print_repository_info: :environment do
  PrintRepositoryInfo.perform url: ENV['repository_url']
end
```
And, we've restored our functionality.
```bash
rake print_repository_info repository_url=https://api.github.com/repos/rails/rails
```
## Homemade console
The last part of our challenge - homemade console.
Great thank to [Sean C Davis](https://www.seancdavis.com/). He inspired me to make the console for the application.
You may find his articles about that by the following links [Add a Console to your Ruby Project](https://www.seancdavis.com/blog/add-console-to-ruby-project/) & [Add a "reload!" Method to your Ruby Console](https://www.seancdavis.com/blog/add-reload-method-to-ruby-console/).
Let's start!
Create the **bin** folder.
```bash
mkdir bin
```
Add console script by the following path **bin/console**.
```ruby
#!/usr/bin/env ruby

require 'irb'
require_relative File.join(File.dirname(File.expand_path(__dir__)), 'config/application')

def reload!
  puts Application.load_libs
end

IRB.start
```
At the next step, we have to make this script executable by the following command.
```bash
chmod +x bin/console
```
Now, we can run our console and check it.
```ruby
# bin/console
PrintRepositoryInfo.perform(url: 'https://api.github.com/repos/rails/rails')
```
As a bonus, we've added the **reload!** method. So, now you can debug your code without reloading the whole IRB console.
## Conclusion
That's all.
Now, you can build a small ruby application with code autoload, your own console, and Bundler.
I hope the article was useful for you.

Besh wishes
PG