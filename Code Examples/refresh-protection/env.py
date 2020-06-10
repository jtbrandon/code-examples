# Python script to disable deploying to a given env
# This process alters the Octopus Teams' environments
# Writen by: Jamison Brandon
# Date: 01/16/2020

import sys, json
import re
import requests, argparse

# arguments passed
parser = argparse.ArgumentParser(description="Args for Script")
my_group = parser.add_mutually_exclusive_group(required=True)
my_group.add_argument('-d', '--disable', action='store_true', help='disable')
my_group.add_argument('-e', '--enable', action='store_true', help='enable')
parser.add_argument('envs', type=str, nargs=argparse.REMAINDER, help='environments')
args = parser.parse_args()

# Octopus Config; NVO_TEAM is the team to edit (In future this may be made into a list to have multiple teams edited)
nvo_team = "Teams-4"
octo_session = requests.Session()
octo_session.url = "https://octopus.yleo.us"
octo_apikey = "API-XXXX"
octo_session.headers = {
    'X-Octopus-ApiKey': octo_apikey
}

# atoi and Natural_keys are for human sorting of the environments list
# *******************SORTING SECTION*******************
def atoi(text):
    return int(text) if text.isdigit() else text

def natural_keys(text):
    '''
    alist.sort(key=natural_keys) sorts in human order
    http://nedbatchelder.com/blog/200712/human_sorting.html
    (See Toothy's implementation in the comments)
    '''
    return [atoi(c) for c in re.split(r'(\d+)', text)]
# *****************************************************


# This function will take in the env argument passed to the script and find the ID needed to add/remove env to variables list
def findEnv(envs):
    envIDList = []
    envRequest = getReq("environments", "all")
    for env in envs:
        print("**** Finding Environment-ID for env: " + env)
        for singleEnv in envRequest:            
            if env == singleEnv["Name"] :
                envIDList.append(singleEnv["Id"])
    return envIDList

# This function is to submit GET api requests to Octopus
def getReq(apiType, servID):
    try:
        req = octo_session.get("{}/api/{}/{}".format(octo_session.url, apiType, servID)).json()
        return req
        if req.status_code != 200:
            print(req.text)
            raise Exception('*! Recieved non 200 response while sending response to Octopus.')
    except requests.exceptions.RequestException as e:
        if req is not None:
            print(req.text)
        print(e)
        raise

# This function is to submit PUT api requests to Octopus
def putReq(apiType, teamID, datadump):
    print("**** Sending the edited Teams data list up\n")
    try:
        varsend = octo_session.put("{}/api/{}/{}".format(octo_session.url, apiType, teamID), data=json.dumps(datadump))
        if varsend.status_code != 200:
            print(varsend.text)
            raise Exception('*! Recieved non 200 response while sending response to Octopus.')
    except requests.exceptions.RequestException as e:
        if varsend != None:
            print(varsend.text)
        print(e)
        raise

# This function will take in the team data for the environments to either disable or enable
# It will check if the env is enabled/disabled
def able(teamData, envs_to_able):
    envList = teamData['EnvironmentIds']
    for env in envs_to_able:
        if args.enable == True:
            if env not in envList:
                print("**** Adding env: {} permissions to {}".format(env, nvo_team))
                teamData['EnvironmentIds'].append(env)
            else:
                print(
                    "*? The env: {} appears to already be enabled, skipping it".format(env))
        elif args.disable == True:
            if env in envList:
                print("**** Removing " + env)
                teamData['EnvironmentIds'].remove(env)
            else:
                print(
                    "*? It appears the env: {}  has already been disabled or does not exist, skipping it".format(env))
        teamData['EnvironmentIds'].sort(key=natural_keys)
    putReq('teams', nvo_team, teamData)

# Main Function to gather the envID's, TeamData and then either enable or disable.
def main():
    env = args.envs
    teamData = getReq('Teams', nvo_team)
    able(teamData, findEnv(env))
    print("Success!!")

if __name__ == "__main__":
    main()
