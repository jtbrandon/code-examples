#!/usr/bin/env python3

import subprocess
import os
import sys
import time
import argparse
import re
from pathlib import Path


jrepo = "ssh://git@git.youngliving.com:7999/db/release-build.git"
current = os.getcwd()
parent_dir = Path(current).parent.parent
reP = Path(current)
rePath = reP / "build.py"
win_tempFolder = current + "\\tempFolder"
uni_tempFolder = current + "/tempFolder"


def gitClone(repo):
    print("**** Cloning and CD into " + repo)
    subprocess.call(["git", "clone", repo])
    gitCD(repo)


def gitCD(repo):
    gitName = re.search(r'(?=([^/]*$)).*(?=\.git)', repo)[0]
    print("New directory " + gitName)
    os.chdir(gitName)
    return gitName


def change_dir(new_folder):
    print("**** Changing directory to " + str(new_folder))
    os.chdir(new_folder)
    os.system("pwd")


def del_tempFolder():
    print("**** Deleting the temp folder")
    time.sleep(3)
    if os.name == "nt":
        e = subprocess.Popen(["powershell.exe", "Remove-item", "-Path",
                              str(win_tempFolder), "-recurse", "-force"], stdout=sys.stdout)
        e.communicate()
    else:
        subprocess.call(["rm", "-rf", uni_tempFolder])


def main(repo, DryRun):
    print("**** Checking OS type")
    if os.name == "nt":
        k = subprocess.Popen(["powershell.exe", "New-Item", "-ItemType",
                              "directory", "-Path", win_tempFolder], stdout=sys.stdout)
        k.communicate()
    elif os.name == "posix":
        subprocess.call(["mkdir", uni_tempFolder])

    change_dir("tempFolder")

    gitClone(jrepo)

    gitClone(repo)

    print("**** Running relb2.py scripty")
    if DryRun == True:
        DryRun = "-d"
        print("*******   THIS IS A DRY RUN TO MAKE SURE THINGS   ******* \
			  \n*******  WORK WITHOUT ACTUALLY MESSING THINGS UP  ******* \
			  \n*******               THANK YOU                   *******")
    else:
        DryRun = ""
    py_command = "python3 {} {}".format(str(rePath), DryRun)
    print(py_command)
    os.system(py_command)
    change_dir(parent_dir)
    del_tempFolder()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description='Running Version Script and PR')
    parser.add_argument('-r', '--repo', dest='repo', required=True,
                        default='false', help='Repo to clone URL')
    parser.add_argument('-d', '--dry_run', dest='dry_run',
                        action="store_true", help='Attempt Dry Run?')
    args = parser.parse_args()

    # run command
    main(args.repo, args.dry_run)
