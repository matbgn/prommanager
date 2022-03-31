# 4.0.0
- Rename project to be more compliant with Linux Trademark usage
- Add communication services based on PingMe CLI (https://github.com/kha7iq/pingme)
- Supported bridges are Microsoft Teams, Telegram, Slack, etc. see PingMe for full list
- Retrieve .env values via shdotenv library for more robustness (https://github.com/ko1nksm/shdotenv) 
- [WARNING] Breaking change: for prometheus full flag (seems to be the last breaking change for existing flags)

# 3.0.0
- Ensure version numbers are present on fresh install
- Update corresponding command on README.md
- Add blackbox_exporter
- Set ipv4 as preferred protocol for blackbox_exporter
- Add sample list of URL to be watched
- Add Alertmanager
- Split config and init for further developments
- Add an update config option to edit sensitive data in an .env file
- [WARNING] Breaking changes: arguments for install, exec, kill, status switched to lowercase for single letter

# 2.0.0
- Add an adaptative verbose mode (-vv for WARN, -vvv for INFO, -vvvv for DEBUG)
- Improve versions retrieving
- Check for argument when mandatory
- [WARNING] Breaking change: Split display and retrieve options
- Make get and display versions working with apps flags
- Add possibility to start/stop apps separately
- Retrieve status for each app independently via parameter
- Add possibility to remove apps independently of each other

# 1.0.0
- Rewrite option argument parsing
- [WARNING] Breaking changes for script arguments
- Use lsof in favour of netstat for listening open ports
- Add sudo rights control at launch
- Overwrite version to be installed if tag curl OK
- [INFO] Introduction of first [SemVer](https://semver.org/) version