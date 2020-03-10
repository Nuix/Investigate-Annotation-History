# Menu Title: Investigate Annotation History
# Needs Case: true
# Michael Fowler 2016-05-06

require 'json'
require 'set'

$file = "C:/temp/testoutput.csv"

class HistoryAndCounts

	def initialize()
		@secured_fields = Hash.new
		@wra_field_prefix = "md_question_"
		getSecuredFieldNames
		@tags = Set.new
		@tags = $current_case.getAllTags
	end
	
	def getSecuredFieldNames()
		$current_case.getCustomMetadata().select { |key, value| key[0..@wra_field_prefix.size - 1] == @wra_field_prefix }.each do |e| 
			@secured_fields[e[0]] = JSON.parse(e[1])['displayText']
		end
	end
	
	def getHistoryFilter()
		return {:startDateAfter => nil,
			:startDateBefore => nil,
			:type => "annotation",
			:user => nil,
			:order => "start_date_ascending"}
	end
	
	def getDateTimeUser(e)
		return "#{e.getEndDate.to_s[0..9]},#{e.getEndDate.to_s[11..18]},#{e.getUser.to_s}"
	end

	def getRow(item, event_info)
		return "#{item.getGuid},\"#{item.getName}\",#{item.getKind},#{event_info}"
	end
	
	def each_record &block
		$current_case.getHistory(getHistoryFilter()).each do |e|
			if  @secured_fields.key?(e.getDetails["fieldName"])
				event_info = "Secured Field,#{getDateTimeUser(e)},#{@secured_fields[e.getDetails["fieldName"]]},#{e.getDetails["value"]}"
				e.getAffectedItems.each do |item| 
					yield getRow(item, event_info)
				end
			elsif e.getDetails["tag"] != nil
				event_info = "Tag,#{getDateTimeUser(e)},#{e.getDetails["tag"]},,"
				e.getAffectedItems.each do |item| 
					yield getRow(item, event_info)
				end
			end
		end
	end

	def GetCountsString
		countsStr = "\nField/Tag,Count\n"
		@tags.each do |tag|
			count = $current_case.count("tag:\"#{tag}\"")
			countsStr = countsStr + "#{tag},#{count}\n"
		end
		@secured_fields.each do |key, value|
			count = $current_case.count("custom-metadata:#{key}:*")
			countsStr = countsStr + "#{@secured_fields[key]},#{count}\n"
		end
		return countsStr
	end
end

begin
	hac = HistoryAndCounts.new()
	File.open($file, "w") do |f|
		f.puts "GUID,Item Name,Item Type,Annotation Type,Date,Time,User,Field/Tag,Value"
		hac.each_record do |record|
			f.puts record
		end
		f.puts hac.GetCountsString
	end

end