#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'rubygems'
require 'mechanize'
require 'csv'

#puts Mechanize::AGENT_ALIASES

a = Mechanize.new { |agent|
  agent.user_agent_alias = 'Mac Safari'
}

# Открываем сессию вконтакта
a.get('http://vk.com/') do |page|
  my_page = page.form_with(:action => 'https://login.vk.com/?act=login') do |f|
    f.email  = 'логин'
    f.pass   = 'пароль'
  end.click_button
end

# Идём на loveplanet и делаем авторизацию через OAUTH во вконтакт
a.get('http://loveplanet.ru') do |page|
  link = page.links_with(:class => 'register_href_2')
  a.click(link[0])
end

# Создаём два файла, в одном города московской области, в другом метро для Москвы
# a.get('http://loveplanet.ru/a-expsearch/') do |page|
#   CSV.open('city.csv', 'w') do |csv|
#     page.search('//*[@id="city"]/option').each do |city|
#       csv << [city.attributes['value'], city.text]
#     end
#   end
#   CSV.open('metro.csv', 'w') do |csv|
#     page.search('//*[@id="metro"]/option').each do |metro|
#       csv << [metro.attributes['value'], metro.text]
#     end
#   end
# end

$i = 1  # счётчик городов
$p = 0  # счётчик страниц
$m = 0  # счётчик метро

@city = Array.new
@metro = Array.new

CSV.foreach('city.csv', 'r') do |row|
  city_id, city_name = row
  @city.push [city_id, city_name]
end

CSV.foreach('metro.csv', 'r') do |row|
  metro_id, metro_name = row
  @metro.push [metro_id, metro_name]
end

# Через поиск ограничение 1001 страниц
# Ограничение обходим сужая поиск
while $i < @city.length do
  $a = 18 # счётчик возраста
  while $a <= 35 do
    url = 'http://loveplanet.ru/a-expsearch/d-1/pol-1/spol-2/bage-' + $a.to_s + '/tage-' + $a.to_s + '/foto-1/country-3159/region-4312/city-' + @city[$i][0] + '/metro-' + @metro[$m][0] + '/who-3/m_purp-on/p-' + $p.to_s + '/'
    puts url+"\n"
    a.get(url) do |page|
      if page.parser.xpath('//*[@id="content"]/div[2]/table/tr/td/div').text == 'Поиск не дал результатов'
        if @city[$i][0] == 4400 && $m < @metro.length
          $m += 1
          $p = 0
          next
        else
          $p = 0
          $a += 1
          $m = 0
          next
        end
      else
        page.links_with(:class => 'name').each do |link|
          a.get('http://loveplanet.ru'+link.href) do |anketa|
            # здесь открывается анкета и можно её парсить
            puts 'http://loveplanet.ru'+link.href+"\n"
          end
          sleep 0.5 + rand # timeout между запросами к анкетам
        end
        $p += 1
      end
    end
  end
  $i += 1
end
