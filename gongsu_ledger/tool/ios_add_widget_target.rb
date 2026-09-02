#!/usr/bin/env ruby
# 홈 위젯 확장 타깃(GongsuWidget)을 ios/Runner.xcodeproj 에 추가한다. 여러 번 실행해도 안전.
#
#   gem install xcodeproj
#   ruby tool/ios_add_widget_target.rb
#
# 하는 일:
#   1. Runner 타깃에 App Group 엔타이틀먼트(Runner/Runner.entitlements) 연결
#   2. GongsuWidget 앱 확장 타깃 생성 (Swift 소스, Info.plist, 엔타이틀먼트)
#   3. Runner → GongsuWidget 의존성 + "Embed Foundation Extensions" 복사 단계
require 'xcodeproj'

# 컨테이너/CI 처럼 LANG 이 없는 환경에서도 pbxproj(UTF-8)를 읽을 수 있게.
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

ROOT = File.expand_path('..', __dir__)
PROJECT_PATH = File.join(ROOT, 'ios', 'Runner.xcodeproj')
WIDGET = 'GongsuWidget'
BUNDLE_ID = 'com.gongsujangbu.gongsuLedger.GongsuWidget'
DEPLOYMENT_TARGET = '15.0'

project = Xcodeproj::Project.open(PROJECT_PATH)
runner = project.targets.find { |t| t.name == 'Runner' } or abort('Runner 타깃을 찾지 못했습니다')

# 1. Runner 엔타이틀먼트
runner_group = project.main_group['Runner'] or abort('Runner 그룹을 찾지 못했습니다')
unless runner_group.files.any? { |f| f.path == 'Runner.entitlements' }
  runner_group.new_file('Runner.entitlements')
end
runner.build_configurations.each do |c|
  c.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
end

# iPhone 전용 — iPad 심사(2.1)에서 큰글씨 레이아웃 문제를 피한다. iPad 지원은 별도 결정.
runner.build_configurations.each { |c| c.build_settings['TARGETED_DEVICE_FAMILY'] = '1' }

def configure_widget_configs(project, widget)
  group = project.main_group[WIDGET] || project.main_group.new_group(WIDGET, WIDGET)
  xcconfig = group.files.find { |f| f.path == "#{WIDGET}.xcconfig" } || group.new_file("#{WIDGET}.xcconfig")
  widget.build_configurations.each do |c|
    c.base_configuration_reference = xcconfig
    c.build_settings['TARGETED_DEVICE_FAMILY'] = '1'
  end
end

if project.targets.any? { |t| t.name == WIDGET }
  configure_widget_configs(project, project.targets.find { |t| t.name == WIDGET })
  puts "#{WIDGET} 타깃이 이미 있습니다 — 설정만 갱신"
else
  # 2. 확장 타깃
  widget = project.new_target(:app_extension, WIDGET, :ios, DEPLOYMENT_TARGET)
  group = project.main_group.new_group(WIDGET, WIDGET)
  swift = group.new_file("#{WIDGET}.swift")
  group.new_file('Info.plist')
  group.new_file("#{WIDGET}.entitlements")
  widget.add_file_references([swift])
  # xcodeproj 가 자동으로 넣는 Foundation.framework 참조는 SDK 버전이 박힌 경로라 제거한다.
  widget.frameworks_build_phase.files.to_a.each do |bf|
    ref = bf.file_ref
    bf.remove_from_project
    ref&.remove_from_project
  end
  frameworks_group = project.main_group['Frameworks']
  if frameworks_group
    ios_group = frameworks_group['iOS']
    ios_group.remove_from_project if ios_group && ios_group.children.empty?
    frameworks_group.remove_from_project if frameworks_group.children.empty?
  end
  # WidgetKit/SwiftUI 는 Swift `import` 로 자동 링크된다 — SDK 버전이 박힌 프레임워크 경로를
  # pbxproj 에 남기지 않기 위해 명시 링크는 하지 않는다.

  widget.build_configurations.each do |c|
    s = c.build_settings
    s['PRODUCT_BUNDLE_IDENTIFIER'] = BUNDLE_ID
    s['PRODUCT_NAME'] = '$(TARGET_NAME)'
    s['INFOPLIST_FILE'] = "#{WIDGET}/Info.plist"
    s['GENERATE_INFOPLIST_FILE'] = 'YES'
    # 표시 이름(공수장부)은 GongsuWidget/Info.plist 에 둔다 — pbxproj 는 ASCII 로 유지.
    s['CODE_SIGN_ENTITLEMENTS'] = "#{WIDGET}/#{WIDGET}.entitlements"
    s['CODE_SIGN_STYLE'] = 'Automatic'
    s['CURRENT_PROJECT_VERSION'] = '$(FLUTTER_BUILD_NUMBER)'
    s['MARKETING_VERSION'] = '$(FLUTTER_BUILD_NAME)'
    s['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
    s['SWIFT_VERSION'] = '5.0'
    s['TARGETED_DEVICE_FAMILY'] = '1'
    s['SKIP_INSTALL'] = 'YES'
    s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks']
    s['SWIFT_EMIT_LOC_STRINGS'] = 'YES'
    if c.name == 'Debug'
      s['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
      s['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = 'DEBUG $(inherited)'
    else
      s['SWIFT_OPTIMIZATION_LEVEL'] = '-O'
    end
  end

  # 3. Runner 에 포함
  runner.add_dependency(widget)
  embed = runner.new_copy_files_build_phase('Embed Foundation Extensions')
  embed.dst_subfolder_spec = '13' # PlugIns
  embed.dst_path = ''
  build_file = embed.add_file_reference(widget.product_reference)
  build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
  configure_widget_configs(project, widget)
  puts "#{WIDGET} 타깃 추가"
end

project.save
puts "저장: #{PROJECT_PATH}"
