Heavily based on https://csdprojects.co.uk/ddwrt/, I've added some changes which I want to keep track of.

Extract the content of this zip file into /tmp/ on your router which should create a directory called MyPage.

The /tmp/MyPage/config.sh file contains some configuration options for the utility. You'll need to reboot the router for the changes to take effect.

Run the following via a telnet/ssh connection to your router:

    ln -s /tmp/MyPage/www/qos_conntrack.js /tmp/www/
    chmod +x /tmp/MyPage/*.sh
    nvram set mypage_scripts="/tmp/MyPage/qos_conntrack.sh"
    nvram commit
    /tmp/MyPage/traffic_monitor.sh &

The terminal will appear to hang, this is normal, we are just doing this to test everything works before making it permanent.
Browse to your router control panel then click on My Page which should have appeared in the Status section.
If everything works, continue, if not then check you did everything above.

You will need to find a way to permanently store the files on your router, the easiest is to enable jffs2 if your router supports it.
Assuming you use jffs2 do the following after the above:

    cp -r /tmp/MyPage /jffs/

Alternatively, you could use a USB drive and change /jffs to /tmp/mnt/sda1 or wherever it was mounted.

Go into Administration, Commands.
If you already have a startup script click Edit and put the command below at the end of it then click Save Startup.
If you do not, put the following into the commands box (make sure its empty first) then click Save Startup.

    cp -r /jffs/MyPage /tmp/
    ln -s /tmp/MyPage/www/qos_conntrack.js /tmp/www/
    /tmp/MyPage/traffic_monitor.sh&

My Page should now automatically be available every time you reboot the router.
