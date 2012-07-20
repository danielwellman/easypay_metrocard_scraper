#! /usr/bin/env ruby

require 'rubygems'
require 'capybara'
require 'capybara/dsl'
require 'capybara-webkit'


class Scraper

  # Don't attempt to start a local server
  Capybara.run_server = false
  # Use the capybara-webkit headless driver
  # Capybara.javascript_driver = :webkit
  Capybara.default_driver = :webkit
  Capybara.app_host = 'http://www.easypaymetrocard.com'

  include Capybara::DSL
  def run(account_number, password, start_date, end_date)
    # Login
    visit("/")
    fill_in("iAccountNumber", :with => account_number)
    fill_in("iPassword", :with => password)
    click_button("Signin")
    
    # Account Summary Page
    click_link("Account Activity")

    # Account Activity Page
    fill_in("HStartDate", :with => start_date)
    fill_in("HEndDate", :with => end_date)
    find("#Go1").click

    # Print the header row
    puts find(:xpath, "//table[@id='StatementTable']/tbody/tr").text

    begin
      payment_rows = all(:xpath, "//table[@id='StatementTable']/tbody/tr[contains(., 'Payment Received')]")
      payment_rows.each { |tr| puts tr.text }   

      if page.has_link? ("Next")
        click_link("Next")
      else
        @done = true
      end
    end while not @done

  end
end

if (ARGV.size != 4)
  puts "Usage: ruby charges.rb <pin> <password> <start_date> <end_date>"
  puts
  puts "- Date format is MM/DD/YYYY"
  exit(1)
end

scraper = Scraper.new
scraper.run(ARGV[0], ARGV[1], ARGV[2], ARGV[3])