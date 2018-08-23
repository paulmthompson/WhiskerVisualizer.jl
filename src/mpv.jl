
myseek(x)=pipeline(`echo seek $x absolute`,`socat - /tmp/mpvsocket`)

set_gamma(x)=pipeline(`echo set gamma $x`,`socat - /tmp/mpvsocket`)

set_brightness(x)=pipeline(`echo set brightness $x`,`socat - /tmp/mpvsocket`)

mpv_open(x) = readandwrite(`mpv --hr-seek=always --input-ipc-server=/tmp/mpvsocket --quiet --osdlevel=0 $x`)

const pause_cmd = pipeline(`echo 'set pause yes'`,`socat - /tmp/mpvsocket`)
