#!/usr/bin/env ruby
# encoding: utf-8
# ruby: 2.0
=begin
This script will comment and close open pull requests on github

Written in 2016 by tsaitgaist

To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.

You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>
=end
require 'octokit' # github API library (use 'gem install octokit' to install it)

# personal access tokens (https://github.com/settings/tokens)
# ensure this user has public_repo permissions to be able to comment and close issues
token = ""

# pull requests can be found based on multiple aspects
# list of repositories
repos = []
# list of users (this will use all repositories from this user)
users = []
# list of custom searches
searches = []

# the comment to leave on the pull request when closing
@comment = ""

puts "#{File.basename(__FILE__)} will comment and close all pull requests"
puts "the configuration is at the beginning of the script itself"
puts

# ensure all parameters are provided
unless token and token.length==40 then
  $stderr.puts "[-] personal access token missing"
  exit 1
end
puts "[i] comment used: #{@comment}" if @comment and !@comment.empty?

# comment and close issues
# provide Sawyer::Resource issues search results
def comment_close_issue(issues)
  issues.items.each do |issue|
    repo = issue.repository_url.split('/')[-2]+'/'+issue.repository_url.split('/')[-1]
    # comment pull request
    if @comment and !@comment.empty? then
      begin
        # use the issue API to comment since the pull request API requires a specific commit id
        @client.add_comment(repo, issue.number, @comment)
        puts "\t[+] pull request #{issue.number} on #{repo} commented"
      rescue Octokit::NotFound => error
        $stderr.puts "\t[-] could not comment pull request"
        $stderr.puts "\t[i] ensure this user has the right permissions (public_repo and write)"
      end
    end
    # close pull request
    begin
      # use the issue number since a pull request is also an issue
      @client.close_pull_request(repo, issue.number)
      puts "\t[+] pull request #{issue.number} on #{repo} closed"
    rescue Octokit::NotFound => error
      $stderr.puts "\t[-] could not comment pull request"
      $stderr.puts "\t[i] ensure this user has right permissions (public_repo and write)"
    end
  end
end

# get access to the github API
@client = Octokit::Client.new(:access_token => token)

# go through all repositories
repos.each do |repo|
  puts "[i] repository: #{repo}"
  # get open pull requests (pull requests are a type of issue)
  issues = @client.search_issues("repo:#{repo} type:pr state:open")
  puts "\t[i] found #{issues.total_count} open pull request(s)"
  # comment and close all pull requests
  comment_close_issue(issues)
end
# go through all users
users.each do |user|
  puts "[i] user: #{user}"
  # get open pull requests (pull requests are a type of issue)
  issues = @client.search_issues("user:#{user} type:pr state:open")
  puts "\t[i] found #{issues.total_count} open pull request(s)"
  # comment and close all pull requests
  comment_close_issue(issues)
end
# go through all repositories
searches.each do |search|
  puts "[i] search: #{search}"
  # get open pull requests (pull requests are a type of issue)
  issues = @client.search_issues("#{search} type:pr state:open")
  puts "\t[i] found #{issues.total_count} open pull request(s)"
  # comment and close all pull requests
  comment_close_issue(issues)
end
