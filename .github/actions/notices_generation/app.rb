# frozen_string_literal: true

# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'cocoapods'
require 'octokit'
require 'optparse'
require 'tmpdir'
require 'xcodeproj'
require 'plist'

DEFAULT_TESTAPP_TARGET = "testApp"

# TODO: Inputs
PODS=["FirebaseABTesting"]
MIN_IOS_VERSION='10.0'
SOURCES=["https://cdn.cocoapods.org/"]

if not ENV['INPUT_PODS'].nil?
  PODS = ENV['INPUT_PODS'].split(/[ ,]/)
end
if not ENV['INPUT_SOURCES'].nil?
  SOURCES = ENV['INPUT_SOURCES'].split(/[ ,]/)
end
if not ENV['INPUT_MIN_IOS_VERSION'].nil?
  MIN_IOS_VERSION = ENV['INPUT_MIN_IOS_VERSION']
end

def create_podfile(path: , sources: , target: , pods: [], min_ios_version: )
  output = ""
  for source in sources do 
    output += "source \'#{source}\'\n"
  end

  output += "platform :ios, #{min_ios_version}\n"
  output += "target \'#{target}\' do\n"
  for pod in pods do 
    output += "pod \'#{pod}\'\n"
  end 
  output += "end\n"

# Remove default footers and headers generated by CocoaPods.
  output += "
    class ::Pod::Generator::Acknowledgements
      def header_text
    ''
      end
      def header_title
     ''
      end
      def footnote_text
      ''
      end
    end
  "
  puts output
  podfile = File.new("#{path}/Podfile", "w")
  podfile.puts(output)
  podfile.close
end

def generate_notices_content(sources: SOURCES, pods: PODS, min_ios_version: MIN_IOS_VERSION)
  content = ""
  Dir.mktmpdir do |temp_dir|
    Dir.chdir(temp_dir) do
      project_path = "#{temp_dir}/barebone_app.xcodeproj"
      project_path = "barebone_app.xcodeproj"
      project = Xcodeproj::Project.new(project_path)
      project.new_target(:application, DEFAULT_TESTAPP_TARGET, :ios)
      project.save()
      create_podfile(path: temp_dir, sources: sources, target: DEFAULT_TESTAPP_TARGET,pods: pods, min_ios_version: min_ios_version)
      pod_install_result = `pod install --allow-root`
      puts pod_install_result
      licences = Plist.parse_xml("Pods/Target Support Files/Pods-testApp/Pods-testApp-acknowledgements.plist")
      for licence in licences["PreferenceSpecifiers"] do
          content += "#{licence["Title"]}\n"
          content += "#{licence["FooterText"]}\n"
      end
    end
  end
  return content.strip
end

def main()
  content = generate_notices_content()
  notices = File.new("./NOTICES", "w")
  notices.puts(content)
  notices.close
end 

main()
