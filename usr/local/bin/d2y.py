# Anagnostakis Ioannis GR 2023
# converter systemd services to sysvinit scripts for Slackware use.

# Simple to use:
# python3 d2v.py /etc/systemd/system/some-service.service /path/ouput

# 2 files will be in the output, one is the SysVinit script and the other is an explanation file for manually setups if needed...
# Assume: groups ,dependencies, etc... 

import sys
import os

def parse_unit_file(unit_file):
    """
    Parse a systemd unit file and extract relevant information.
    """
    data = {}
    with open(unit_file, 'r') as f:
        for line in f:

            line = line.strip().split('#')[0].strip()
            if '=' in line:
                key, value = line.split('=', 1)
                data[key.strip()] = value.strip()
    return data

def get_dependencies(unit_data):
    """
    Extract dependencies from the [Unit] section of the unit data.
    """
    dependencies = []
    after = unit_data.get('After', '')
    requires = unit_data.get('Requires', '')
    wants = unit_data.get('Wants', '')
    before = unit_data.get('Before', '')

    dependencies.extend(after.split())
    dependencies.extend(requires.split())
    dependencies.extend(wants.split())
    dependencies.extend(before.split())

    return dependencies

def generate_init_script(unit_file, output_dir):
    """
    Generate a SysV init script based on systemd unit file data.
    """
    unit_data = parse_unit_file(unit_file)

    service_name = os.path.basename(unit_file).replace('.service', '')
    description = unit_data.get('Description', 'No description available')
    exec_start = unit_data.get('ExecStart', '')
    exec_stop = unit_data.get('ExecStop', '')

    # Modify the exec_start and exec_stop lines to use '/usr/bin/complex start' and '/usr/bin/complex stop'
    exec_start = exec_start.replace('/usr/bin/complex-start', '/usr/bin/complex start')
    exec_stop = exec_stop.replace('/usr/bin/complex-stop', '/usr/bin/complex stop')

    init_script = f"""#!/bin/sh
# Init script for {service_name}
# Slackware SysV init style
# Generated from {unit_file}

# Description: {description}

# Explanation of most used systemd options:
# - Dependencies: Manage dependencies manually within this script.
# - ConditionPathExists: Check for file existence within this script.
# - Exec Commands: Include commands from ExecStart, ExecReload, ExecStop, and ExecStopPost
#   within the start() and stop() functions.
# - Restart on Failure: Implement custom restart logic within this script.
# - User and Group: Specify the user and group within this script.
# - Restart Delay and Timeout: Customize restart delay and timeout using timers or sleep intervals.
# - Service Type: Define the service type using custom logic.
# - PID File: Create and manage a PID file manually.
# - Security Features: Implement security features within this script.
# - Target: In SysV init, there is no direct equivalent to systemd targets.
#   Use placement and naming conventions within /etc/rc.d/ directories to control service startup.
# - EnvironmentFile: Specifies the path to an environment file that sets environment
#   variables for the service. In SysV init, you may need to manually export environment
#   variables within the script, whereas systemd provides a dedicated option for this purpose.
# - RestartSec: Sets the time to wait (in seconds) before restarting the service after
#   an unexpected exit. In SysV init scripts, you might need to implement custom logic
#   for restart delays, whereas systemd simplifies this with the RestartSec option.

start() {{
    echo "Starting {service_name}..."
    {exec_start}
    # Add any additional start commands here
}}

stop() {{
    echo "Stopping {service_name}..."
    {exec_stop}
    # Add any additional stop commands here
}}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        start
        ;;
    *)
        echo "Usage: $0 {{start|stop|restart}}"
        exit 1
        ;;
esac

exit 0
"""

    output_script = os.path.join(output_dir, service_name)
    with open(output_script, 'w') as f:
        f.write(init_script)


def generate_explanation_file(unit_file, output_dir):
    """
    Generate an explanation file for systemd options in the service file.
    """
    unit_data = parse_unit_file(unit_file)


    explanation = f"""Explanation of systemd options in {unit_file}:

"""
    for key, value in unit_data.items():
        explanation += f"- {key}: {value}\n"

    package_name = os.path.basename(unit_file).replace('.service', '')
    explanation_file = os.path.join(output_dir, f'{package_name}-explanation.txt')  # Define the explanation file name

    with open(explanation_file, 'w') as f:
        f.write(explanation)


    additional_explanation = """# 
# Explanation of SysV init conventions (most): 
#
# - Dependencies: Manage dependencies manually within this script.
# - ConditionPathExists: Check for file existence within this script.
# - Exec Commands: Include commands from ExecStart, ExecReload, ExecStop, and ExecStopPost
#   within the start() and stop() functions.
# - Restart on Failure: Implement custom restart logic within this script.
# - User and Group: Specify the user and group within this script.
# - Restart Delay and Timeout: Customize restart delay and timeout using timers or sleep intervals.
# - Service Type: Define the service type using custom logic.
# - PID File: Create and manage a PID file manually.
# - Security Features: Implement security features within this script.
# - Target: In SysV init, there is no direct equivalent to systemd targets.
# - Use placement and naming conventions within /etc/rc.d/ directories to control service startup.
# - EnvironmentFile: Specifies the path to an environment file that sets environment
#   variables for the service. In SysV init, you may need to manually export environment
#   variables within the script, whereas systemd provides a dedicated option for this purpose.
# - RestartSec: Sets the time to wait (in seconds) before restarting the service after
#   an unexpected exit. In SysV init scripts, you might need to implement custom logic
#   for restart delays, whereas systemd simplifies this with the RestartSec option.
"""

    with open(explanation_file, 'a') as f:
        f.write(additional_explanation)

def main():
    if len(sys.argv) != 3:
        print("Usage: python systemd_to_sysv.py <unit_file> <output_dir>")
        sys.exit(1)

    unit_file = sys.argv[1]
    output_dir = sys.argv[2]

    if not os.path.isfile(unit_file):
        print(f"Error: {unit_file} does not exist.")
        sys.exit(1)

    if not os.path.isdir(output_dir):
        print(f"Error: {output_dir} is not a directory.")
        sys.exit(1)

    generate_init_script(unit_file, output_dir)
    generate_explanation_file(unit_file, output_dir)
    print(f"SysV init script and explanation file generated for {os.path.basename(unit_file)} in {output_dir}")


if __name__ == '__main__':
    main()
