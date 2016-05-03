import requests
import mechanize

# Get Cookies
url = "https://bcsweb.is.berkeley.edu/psc/bcsprd_pub/EMPLOYEE/HRMS/c/COMMUNITY_ACCESS.CLASS_SEARCH.GBL?ucFrom=berkeley"
r = requests.get(url)
cookies = r.cookies

# Create Browser
br = mechanize.Browser()
br.set_cookiejar(cookies)
br.set_handle_equiv(True)
br.set_handle_redirect(True)
br.set_handle_referer(True)
br.set_handle_robots(False)

# Fill in Form
response = br.open(url)
br.select_form('win0')
control = br.form.find_control("SSR_CLSRCH_WRK_SUBJECT_SRCH$0")
control.value = ["AEROSPC"]
br[control.name] = ["AEROSPC"]
# response = br.submit()
