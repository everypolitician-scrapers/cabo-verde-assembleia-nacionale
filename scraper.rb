#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'capybara'
require 'capybara/poltergeist'


Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(
    app,
    # Submit button's onClick references an undefined variable, 'btn_OK'
    {js_errors: false, phantomjs_options: ['--load-images=no']}
  )
end

include Capybara::DSL
Capybara.default_driver = :poltergeist


def when_obsolete(el)
  while el.visible?
  end
rescue Capybara::Poltergeist::ObsoleteNode
  yield
end

def scrape(term, pageno = 1)
  warn "Scraping page #{pageno} of the #{term}th term"
  table = page.find_by_id('ctl00_ContentPlaceHolder1_GridView1')
  table.all(:xpath, './tbody/tr[position() > 1 and position() < last()]').each do |mp|
    tds = mp.all(:xpath, './td')
    link = tds[0].first('a')
    data = {
      id: link[:href][/(\d+)$/, 1],
      name: tds[0].text.strip,
      image: "http://www.parlamento.cv/#{tds[0].find('img')[:src]}",
      party: tds[1].text.strip,
      party_id: tds[1].text.strip,
      area: tds[2].text.strip,
      term: term,
      source: "http://www.parlamento.cv/#{link[:href]}",
    }
    ScraperWiki.save_sqlite([:id, :term], data)
  end

  pageno += 1
  navbar = table.all('tr').last
  if next_page = navbar.all('a[href*="Page"]').find { |n| n.text == pageno.to_s }
    next_page.click
    # Waiting around for ObsoleteNode to be triggered, meaning the MP table's
    # been updated
    when_obsolete(navbar) do
      navbar = table.all('tr').last
      # Now we've got to resubmit the form 'cause the term selection
      # is lost in-between pages
      page.find_by_id('ctl00_ContentPlaceHolder1_btnOK').click
      when_obsolete(navbar) { scrape(term, pageno) }
    end
  end
end

def main
  visit 'http://www.parlamento.cv/deputados2.aspx'
  scrape(9)

  # Reloading the web page to return to the 1st page of the table 'cause it's
  # easier that way
  visit 'http://www.parlamento.cv/deputados2.aspx'
  navbar = page.find_by_id('ctl00_ContentPlaceHolder1_GridView1').all('tr').last
  page.find_by_id('ctl00_ContentPlaceHolder1_DropDownList1').select('VIII')
  page.find_by_id('ctl00_ContentPlaceHolder1_btnOK').click
  when_obsolete(navbar) { scrape(8) }
end

main
