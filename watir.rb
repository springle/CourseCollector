require "watir"
require "json"
require "watir-webdriver/wait"
require "watir-nokogiri"
require "nokogiri"
require "open-uri"

class ScheduleScraper
    
    @@browser = Watir::Browser.new
    @doc = WatirNokogiri::Document.new()
    @info = Hash.new()

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
        Watir::Wait.until { @@browser.link(:id => "CLASS_SRCH_WRK2_SSR_PB_BACK").exists? }
        @doc = WatirNokogiri::Document.new(@@browser.html)
        @info = Hash.new()
        @info["status"] = scrape_element("SSR_CLS_DTL_WRK_SSR_DESCRSHORT") 
        @info["ccn"] = scrape_element("SSR_CLS_DTL_WRK_CLASS_NBR")
        @info["session_type"] = scrape_element("PSXLATITEM_XLATLONGNAME$31$")
        @info["units"] = scrape_element("SSR_CLS_DTL_WRK_UNITS_RANGE")
        @info["instruction_mode"] = scrape_element("INSTRUCT_MODE_DESCR")
        @info["career"] = scrape_element("PSXLATITEM_XLATLONGNAME")
        @info["dates"] = scrape_element("SSR_CLS_DTL_WRK_SSR_DATE_LONG")
        @info["grading"] = scrape_element("GRADE_BASIS_TBL_DESCRFORMAL")
        @info["location"] = scrape_element("CAMPUS_LOC_VW_DESCR")
        @info["meeting_times"] = scrape_element("MTG_SCHED$0")
        @info["meeting_loc"] = scrape_element("MTG_LOC$0")
        @info["instructor"] = scrape_element("MTG_INSTR$0")
        @info["meeting_dates"] = scrape_element("MTG_DATE$0")
        @info["class_capacity"] = scrape_element("SSR_CLS_DTL_WRK_ENRL_CAP")
        @info["enrollment_total"] = scrape_element("SSR_CLS_DTL_WRK_ENRL_TOT")
        @info["available_seats"] = scrape_element("SSR_CLS_DTL_WRK_AVAILABLE_SEATS")
        @info["waitlist_capacity"] = scrape_element("SSR_CLS_DTL_WRK_WAIT_CAP")
        @info["waitlist_total"] = scrape_element("SSR_CLS_DTL_WRK_WAIT_TOT")
        @info["description"] = scrape_element("DERIVED_CLSRCH_DESCRLONG")
        @info["title"] = scrape_element("DERIVED_CLSRCH_DESCR200")
        @info["subtitle"] = scrape_element("DERIVED_CLSRCH_SSS_PAGE_KEYDESCR")

        # Parse title string
        title = @info["title"].split(" ")
        @info["department"] = title[0].delete("^a-zA-Z0-9")
        @info["course_name"] = title[1].delete("^a-zA-Z0-9")

        scrape_ninja_courses(@info["department"], @info["course_name"])

        puts @info
        click_link("CLASS_SRCH_WRK2_SSR_PB_BACK")
    end

    def scrape_ninja_courses(department, course_name)
    	department = correct_nc_department(department)
    	url = "https://ninjacourses.com/explore/1/course/" + department + "/" + course_name + "/#ratings"
    	begin
	    	page = Nokogiri::HTML(open(url))
	    	course_rating = page.css("div.rating-big")[0].text
	    	@info["course_rating"] = course_rating
	    rescue Exception => e
	    	puts "Exception: #{e}"
	    end
    end

    def correct_nc_department(department)
    	return "VIS%20STD" if department == "VISSTD"
    	return "VIS%20SCI" if department == "VISSCI"
    	return department
    end

    def scrape_element(element_id)
        element = @doc.span(:id => element_id)
        if element.exists?
            return element.text
        else
            return nil
        end
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
