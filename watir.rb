require "watir"
require "watir-webdriver/wait"
require "watir-nokogiri"
require "nokogiri"

class ScheduleScraper
    
    @@browser = Watir::Browser.new

    def scrape_subject(subject_name)
        @@browser.select_list(:id => 'SSR_CLSRCH_WRK_SUBJECT_SRCH$0').when_present.select_value(subject_name)
        @@browser.select_list(:id => 'SSR_CLSRCH_WRK_SSR_COMPONENT$5').when_present.select_value("LEC")
        click_link("CLASS_SRCH_WRK2_SSR_PB_CLASS_SRCH")  
        scrape_classes
        click_link("CLASS_SRCH_WRK2_SSR_PB_NEW_SEARCH$3$") 
    end

    def click_link(link_id)
        Watir::Wait.until { @@browser.link(:id => link_id).exists? }
        @@browser.send_keys :escape
        sleep 0.5
        @@browser.link(:id => link_id).when_present.click
    end

    def scrape_classes() 
        Watir::Wait.until { @@browser.link(:id => "CLASS_SRCH_WRK2_SSR_PB_NEW_SEARCH$3$").exists? }  
        page = Nokogiri::HTML.parse(@@browser.html)
        links = page.xpath('//a[starts-with(@id, "MTG_CLASS_NBR")]')
        links.each do |d|
            scrape_course(d.attribute("id").value)
        end
    end 

    def scrape_course(link_id)
        click_link(link_id)
        doc = WatirNokogiri::Document.new(@@browser.html)
        click_link("CLASS_SRCH_WRK2_SSR_PB_BACK")
    end

    def main()
        url = "https://bcsweb.is.berkeley.edu/psc/bcsprd_pub/EMPLOYEE/HRMS/c/COMMUNITY_ACCESS.CLASS_SEARCH.GBL?ucFrom=berkeley"
        @@browser.goto url
        doc = WatirNokogiri::Document.new(@@browser.html)
        subject_list = doc.select(:id => 'SSR_CLSRCH_WRK_SUBJECT_SRCH$0')
        subjects = Array.new()
        subject_list.options.each do |d|
            subjects.push(d.value)
        end

        # Remove empty subject option
        subjects.delete_at(0)

        while !subjects.empty? do
            subject = subjects.pop
            scrape_subject subject 
        end
    end
    
end

scraper = ScheduleScraper.new
scraper.main
