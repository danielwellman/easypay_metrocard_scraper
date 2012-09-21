#! /usr/bin/env ruby

require 'rubygems'
require 'capybara'
require 'capybara/dsl'
require 'capybara-webkit'

class ConsoleListener

  def header_found(header_row)
    puts header_row.text
  end

  def payments_found(payment_rows, page)
    payment_rows.each { |tr| puts tr.text }    
  end
end

class ScreenshotListener    
  def initialize
    @screenshot_number = 0
  end

  def header_found(header_row)
    # Do nothing
  end

  def payments_found(payment_rows, page)
    if (!payment_rows.empty?) 
      page.driver.render "screenshot-#{@screenshot_number}.png"
      @screenshot_number = @screenshot_number + 1
    end
  end
end


class Scraper

  # Don't attempt to start a local server
  Capybara.run_server = false
  # Use the capybara-webkit headless driver
  # Capybara.javascript_driver = :webkit
  Capybara.default_driver = :webkit
  Capybara.app_host = 'http://www.easypaymetrocard.com'

  include Capybara::DSL

  def initialize
    @listeners = [ConsoleListener.new, ScreenshotListener.new]
  end

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

    header_row = find(:xpath, "//table[@id='StatementTable']/tbody/tr")
    @listeners.each { |l| l.header_found(header_row) }

    begin
      payment_rows = all(:xpath, "//table[@id='StatementTable']/tbody/tr[contains(., 'Payment Received')]")
      @listeners.each { |l| l.payments_found(payment_rows, page) }

      if page.has_link? ("Next")
        click_link("Next")
      else
        @done = true
      end
    end while not @done

  end
end

if (ARGV.size != 4)
  puts "Usage: ruby charges.rb <account_number> <password> <start_date> <end_date>"
  puts
  puts "- Date format is MM/DD/YYYY"
  exit(1)
end

scraper = Scraper.new
scraper.run(ARGV[0], ARGV[1], ARGV[2], ARGV[3])