require 'xcodeproj'

project_path = '/Users/msaadani/swift/LireFlow.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "Opened project: #{project_path}"

# 2. Find or Create the 'LireFlow' group (where sources are)
app_group = project.main_group.groups.find { |g| g.display_name == 'LireFlow' }
if app_group.nil?
  puts "Could not find 'LireFlow' group! Available groups: #{project.main_group.groups.map(&:display_name)}"
  # Try to create it? Or maybe it's the main group itself?
  # Sometimes the folder structure matches.
  # If nil, exit.
  exit 1
end

# 3. Find or Create 'Resources' group inside 'LireFlow'
resources_group = app_group.groups.find { |g| g.display_name == 'Resources' }
if resources_group.nil?
  puts "Creating 'Resources' group..."
  resources_group = app_group.new_group('Resources', 'Resources')
end

# 4. Create/Get Localizable.strings variant group
variant_group_name = 'Localizable.strings'
variant_group = resources_group.files.find { |f| f.name == variant_group_name || f.path == variant_group_name }

if variant_group.nil?
    puts "Creating Localizable.strings variant group..."
    variant_group = resources_group.new_variant_group(variant_group_name)
end

# 5. Add translations to the variant group
languages = ['en', 'fr', 'de']
languages.each do |lang|
    file_path = "#{lang}.lproj/Localizable.strings"
    
    # Check if already exists to avoid duplicates
    existing = variant_group.files.find { |f| f.path == file_path }
    
    unless existing
        puts "Adding #{lang} translation..."
        ref = variant_group.new_reference(file_path)
        ref.name = lang
    else
        puts "Language #{lang} already exists."
    end
end

# 6. Add the variant group to the target's resources build phase
target = project.targets.first
puts "Target: #{target.name}"
resources_phase = target.resources_build_phase

if resources_phase.files_references.include?(variant_group)
    puts "Variant group already in build phase."
else
    puts "Adding variant group to build phase..."
    resources_phase.add_file_reference(variant_group)
end

project.save
puts "Project saved successfully."
