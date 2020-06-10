#!/usr/bin/env python3

import subprocess
import os
import sys
import argparse
import requests
#import jenkins
from pathlib import Path

# variables
cwd = os.getcwd()
gvP = Path(cwd).parent
gvPath = gvP / "gv.ps1"
token = 'XXXXX'
url = "https://jenkins.yleo.us/"
#DryRun = sys.argv[1]
#masterbranch = "master"


pshell = "Set-ExecutionPolicy bypass"


class git:
    def __init__(self, release_branch, integration_branch):
        self.release_branch = release_branch
        self.integration_branch = integration_branch
        print("hello")
    
    def pull(self, branch):
        print("**** Pulling the latest using git pull")
        subprocess.call(["git", "pull", "origin", branch])

    def merge(self):
        print("**** Merging {} branch into {}".format(self.integration_branch,
                                                      self.release_branch))
        subprocess.call(["git", "merge", self.integration_branch])

    def checkout(self, branch="master"):
        print("**** Checking out {} branch".format(branch))
        subprocess.call(["git", "checkout", branch])
        if branch != self.release_branch:
            self.pull(branch)

    def create(self):
        print("**** Creating branch: Using git checkout {} {}".format("-b",
                                                                      self.release_branch))
        subprocess.call(["git", "checkout", "-b", self.release_branch])

    def push(self, DryRun):
        i = 0
        while i != 1:
            print("Running version checking Script; See results below")
            print(gvPath)

            # Checking whether to user pwsh or powershell.exe, MacOS and WIndows respectively
            powershell = ''
            if os.name == "posix":
                powershell = "pwsh"
            elif os.name == "nt":
                powershell = "powershell.exe"
                o = subprocess.Popen([powershell, pshell], stdout=sys.stdout)
                o.communicate()
            # subprocess.call([powershell, str(gvPath)])
            p = subprocess.Popen([powershell, str(gvPath)], stdout=sys.stdout)
            p.communicate()
            pick = input(
                "**** About to push {} upstream. Are you ready?(y/n)".format(self.release_branch))
            if pick.lower() == "y":
                print(
                    "**** Pushing new Release Branch: {} up".format(self.release_branch))
                if DryRun == True:
                    print("***** DRY RUN, NOTHING PUSHED *****")
                    print(
                        "**** Normal Run would run:git push --set-upstream origin {}".format(self.release_branch))
                    self.clean()
                else:
                    print("**** PUSHING TO ORIGIN")
                    subprocess.call(
                        ["git", "push", "--set-upstream", "origin", self.release_branch])
                    #print("**** STARTING BUILD ON JENKINS.YLEO.US")
                    #self.buildInJenkins()
                i = 1
            elif pick.lower() == "n":
                print(
                    "**** Please get yourself ready and re-run the script. Thank You ****")
                self.clean()
                i = 1
            else:
                print("******************************************************************* \
					\n**** Sorry, does not compute. Neither y or n was submitted ****/#) \
					\n****   Please prep accordingingly and re-run the script    ****/#")
    
    #This will send the build to be built if it is in the Standard-build
    def buildInJenkins(self):
        repo_URL = subprocess.check_output(["git", "remote", "get-url", "origin"])
        repo_URL = repo_URL.decode('utf-8').rstrip()
        print(repo_URL)
        jenkinsParams = {
            'token': 'pullrequest',
            'branch': self.release_branch,
            'repository': repo_URL
        }
        blacklist = ['ssh://git@git.youngliving.com:7999/nvo/virtual-office.git', 'ssh://git@git.youngliving.com:7999/bsi/bluesteel.git', 'ssh://git@git.youngliving.com:7999/nvo/essential-acl.git', 'ssh://git@git.youngliving.com:7999/pubapi/joymain-api.git', 'ssh://git@git.youngliving.com:7999/la/api-order-fulfillment.git', 'ssh://git@git.youngliving.com:7999/ji/api-shipment-fulfillment-v2.git', 'ssh://git@git.youngliving.com:7999/nvo/virtual-office-tools.git']
        if repo_URL not in blacklist:
            print("sending " + url + " TOKEN: " + token)
            print(jenkinsParams)
            jconn = jenkins.Jenkins(url, username='jbrandon', password=token)
            try:
                #jconn.build_job('standard-build', jenkinsParams)
                version = jconn.get_version()
                print(version)
            except:
                print("Sorry, unknown/unsported Repo URL, please check and try again")
                return
        else:
            print("This repo is not supported for auto build")
            return
        print("File has been started in Jenkins, successfully")
        return

    def clean(self):
        print("**** Cleaning some things up...")
        self.checkout()
        print("**** Deleting {}".format(self.release_branch))
        subprocess.call(["git", "branch", "-D", self.release_branch])


def main(dry_run):
    if dry_run == True:
        print("***** DRY RUN, NOTHING PUSHED *****")
    print("Here is the current directory: " + cwd)
    rel = input(
        "Please enter the version # for the release branch to be created (ie. 1.8 for release/1.8):")
    relBranch = "release/" + rel
    intBranch = input("Please enter the integration branch:")
    instance = git(relBranch, intBranch)
    instance.checkout()
    instance.create()
    instance.checkout(intBranch)
    instance.checkout(relBranch)
    instance.merge()
    instance.push(dry_run)

    print("Success!")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Arguments for scripty")
    parser.add_argument('-d', '--dry_run', dest='dry_run',
                        action="store_true", help='Attempt Dry Run?')
    args = parser.parse_args()

    main(args.dry_run)
