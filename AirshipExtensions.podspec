AIRSHIP_VERSION="14.5.0"

Pod::Spec.new do |s|
    s.version                 = AIRSHIP_VERSION
    s.name                    = "AirshipExtensions"
    s.summary                 = "Airship iOS App Extensions"
    s.documentation_url       = "https://docs.airship.com/platform/ios"
    s.homepage                = "https://www.airship.com"
    s.license                 = { :type => "Apache License, Version 2.0", :file => "LICENSE" }
    s.author                  = { "Airship" => "support@airship.com" }
    s.source                  = { :git => "https://github.com/olx-mena/ios-library.git", :tag => s.version.to_s }
    s.module_name             = "AirshipExtensions"
    s.requires_arc            = true
    s.ios.deployment_target   = "11.0"
    s.default_subspecs        = ["NotificationService", "NotificationContent"]

    s.subspec "NotificationService" do |notificationService|
        notificationService.ios.source_files     = "AirshipExtensions/AirshipNotificationServiceExtension/Source/**/*.{h,m}"
        notificationService.ios.weak_frameworks  = "UserNotifications"
    end

    s.subspec "NotificationContent" do |notificationContent|
        notificationContent.ios.public_header_files  = "AirshipExtensions/AirshipNotificationContentExtension/Source/Public/*.h"
        notificationContent.ios.source_files         = ["AirshipExtensions/AirshipNotificationContentExtension/Source/**/*.{h,m}", "AirshipExtensions/AirshipNotificationContentExtension/Source/Templates/Carousel/**/*.{h,m}", "AirshipExtensions/AirshipNotificationContentExtension/Source/Public/**/*.{h,m}"]
        notificationContent.ios.weak_frameworks      = "UserNotifications"
    end

end
