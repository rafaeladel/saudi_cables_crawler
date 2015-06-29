require "nokogiri"
require 'open-uri'
require 'fileutils'

DATA_URL = "saudi/"
FileUtils.mkpath(DATA_URL) unless File.exist?(DATA_URL)

WIKILEAKS_LINK = "https://wikileaks.org"
BASE_URL = "#{WIKILEAKS_LINK}/saudi-cables/"
PAGING_URL = "?page="
INIT_PAGE = 1
RECOVERY_FILE = "latest_page.txt"

page = Nokogiri::HTML(open("#{BASE_URL}#{PAGING_URL}#{INIT_PAGE}"))
pages_links = page.css("div.wlspagination ul.pagination li a")
no_pages = pages_links.last.text.match("/[0-9]+/") ? pages_links.last.text : pages_links[-2].text

start = File.exists?(RECOVERY_FILE) ? File.read(RECOVERY_FILE).to_i : 1

(start..no_pages.to_i).each do |n|
  puts "PAGE #{n}"
  File.open(RECOVERY_FILE, "wb") { |file| file.write(n) }

  pagination_dir = "#{DATA_URL}#{n}/"
  FileUtils.mkpath(pagination_dir) unless File.exist?(pagination_dir)

  paged_page = Nokogiri::HTML(open("#{BASE_URL}#{PAGING_URL}#{n}"))
  docs_links = paged_page.css("div.results .row .col-md-10 .meta_details a")
  docs_links.each do |l|
    href = l["href"]
    doc_page = Nokogiri::HTML(open("#{BASE_URL}#{href}"))
    dname = doc_page.css("div.container-text h3").children[2].text
    path_name = "#{pagination_dir}#{dname}"
    FileUtils.mkpath(path_name) unless File.exist?(path_name)
    img_obj = doc_page.css("div.container-text div.row div.col-md-6 p a img")


    if img_obj.any?
      img_src = WIKILEAKS_LINK + img_obj[0]["src"]
      img_name = File.basename(img_src)

      puts "\t Getting #{img_name}..."

      File.open("#{path_name}/#{img_name}", "wb") { |file| file.write(open(img_src).read) }

      desc_obj = doc_page.css("div.container-text div.row div.col-md-6 div#uniquer pre")
      if desc_obj.any?
        img_desc = desc_obj.text
        File.open("#{path_name}/text.txt", "wb") { |file| file.write(img_desc) }
      end
    end

  end

end