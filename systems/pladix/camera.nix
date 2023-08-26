{ config, pkgs, ... }:

{
  services.go2rtc = {
    enable = true;
    settings.ffmpeg.bin = "${pkgs.ffmpeg-full}/bin/ffmpeg";
    settings.streams = {
      mjpeg = "ffmpeg:device?video=/dev/video1&input_format=mjpeg&video_size=1280x720";
      h264 = "ffmpeg:device?video=/dev/video1&input_format=yuyv422&video_size=1280x720#video=h264";
    };
  };
}
