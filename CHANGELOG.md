14-MAR-2022: 2.0.0
- Add adaptative verbose mode (-vv for WARN, -vvv for INFO, -vvvv for DEBUG)
- Improve versions retrieving
- Check for argument when mandatory
- Split display and retrieve options
- Make get and display versions working with apps flags
- Add possibility to start/stop apps separately

12-MAR-2022: 1.0.0
- Rewrite option argument parsing
- [WARNING] Breaking changes for script arguments
- Use lsof in favour of netstat for listening open ports
- Add sudo rights control at launch
- Overwrite version to be installed if tag curl OK