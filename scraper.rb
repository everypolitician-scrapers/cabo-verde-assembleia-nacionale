#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'capybara'
require 'capybara/poltergeist'

include Capybara::DSL
Capybara.default_driver = :poltergeist

def scrape(pageno)
  warn "Scraping page #{pageno}"
  table = page.find_by_id('ctl00_ContentPlaceHolder1_GridView1')
  table.all(:xpath, './tbody/tr[position() > 1 and position() < last()]').each do |mp|
    tds = mp.all(:xpath, './td')
    link = tds[0].all('a')[0]
    data = {
      id: link[:href][/(\d+)$/, 1],
      name: tds[0].text.strip,
      image: "http://www.parlamento.cv/#{tds[0].find('img')[:src]}",
      party: tds[1].text.strip,
      party_id: tds[1].text.strip,
      area: tds[2].text.strip,
      term: 9,
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
    {} while navbar.visible? rescue scrape(term, pageno)
  end
end

visit 'http://www.parlamento.cv/deputados2.aspx'
scrape(1)
