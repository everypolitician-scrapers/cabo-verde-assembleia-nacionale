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
  table.all('a[href*="Deputado="]').each do |mp|
    tr = mp.find(:xpath, './/ancestor::tr[1]')
    tds = tr.all('td')
    data = { 
      id: mp['href'][/(\d+)$/, 1],
      name: tds[0].text.strip,
      party: tds[1].text.strip,
      party_id: tds[1].text.strip,
      area: tds[2].text.strip,
      executive: tds[3].text.strip,
      term: 8,
      source: mp['href'],
    }
    puts data
    ScraperWiki.save_sqlite([:id, :term], data)
  end

  pageno += 1
  navbar = table.all('tr').last
  if next_page = navbar.all('a[href*="Page"]').find { |n| n.text == pageno.to_s }
    navbar.click_link(pageno.to_s)
    scrape(pageno)
  end
end



term = {
  id: 8,
  name: 'VIII Legislatura',
  start_date: '2011-03-11',
  source: 'http://www.parlamento.cv/GDActasVIILegislatura.aspx?codActas=182',
}
ScraperWiki.save_sqlite([:id], term, 'terms')

visit 'http://www.parlamento.cv/deputado.aspx'
scrape(1)



